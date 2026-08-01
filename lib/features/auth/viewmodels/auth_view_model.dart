import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/firebase_auth_repository.dart';

final firebaseAuthRepositoryProvider =
    Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
});

/// Firebase auth state. `null` means signed out.
///
/// There are no sign-in/sign-up screens anymore: the app auto-signs-in with a
/// device-level anonymous account so channels persist per install while the
/// user never sees an auth UI.
final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, LocalUser?>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<LocalUser?> {
  StreamSubscription<LocalUser?>? _subscription;
  Future<void>? _ensureSignedInFuture;

  @override
  Future<LocalUser?> build() {
    final repository = ref.watch(firebaseAuthRepositoryProvider);
    _subscription?.cancel();
    _subscription = repository.authStateChanges().listen((user) {
      state = AsyncData(user);
      if (user == null) _ensureSignedIn();
    });
    ref.onDispose(() => _subscription?.cancel());
    final current = repository.currentUser();
    if (current == null) _ensureSignedIn();
    return Future.value(current);
  }

  /// Silently signs in an anonymous account when nobody is signed in, so the
  /// app is always usable without an auth screen.
  Future<void> _ensureSignedIn() {
    return _ensureSignedInFuture ??= ref
        .read(firebaseAuthRepositoryProvider)
        .signInAnonymously()
        .then((user) {
          state = AsyncData(user);
        })
        .catchError((Object error, StackTrace stackTrace) {
          state = AsyncError(normalizeError(error), stackTrace);
        })
        .whenComplete(() => _ensureSignedInFuture = null);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(firebaseAuthRepositoryProvider)
          .signInWithEmail(email: email, password: password);
      state = AsyncData(user);
    } catch (error) {
      state = AsyncError(normalizeError(error), StackTrace.current);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(firebaseAuthRepositoryProvider)
          .register(name: name, email: email, password: password);
      state = AsyncData(user);
    } catch (error) {
      state = AsyncError(normalizeError(error), StackTrace.current);
    }
  }

  /// Sends a Firebase password-reset email. Returns `true` when the email was
  /// dispatched (regardless of whether the account exists, to avoid leaking
  /// account existence).
  Future<bool> resetPassword({required String email}) async {
    state = const AsyncLoading();
    try {
      await ref.read(firebaseAuthRepositoryProvider).sendPasswordReset(email);
      state = const AsyncData(null);
      return true;
    } catch (error) {
      state = AsyncError(normalizeError(error), StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(firebaseAuthRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (error) {
      state = AsyncError(normalizeError(error), StackTrace.current);
    }
  }

  /// Updates the profile (name + email). Returns a message for the UI: `null`
  /// when nothing needs attention, a notice on a successful email change
  /// (Firebase sends a verification email), or the error message on failure.
  Future<String?> updateProfile({String? name, String? email}) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    final emailChanged =
        email != null && email.trim().isNotEmpty && email.trim() != current.email;
    try {
      final user = await ref
          .read(firebaseAuthRepositoryProvider)
          .updateProfile(name: name, email: email);
      state = AsyncData(user);
      if (emailChanged) {
        return 'A verification email was sent to ${email.trim()}. '
            'Your email updates once you confirm the link.';
      }
      return null;
    } catch (error) {
      final normalized = normalizeError(error);
      state = AsyncError(normalized, StackTrace.current);
      return normalized.message;
    }
  }
}
