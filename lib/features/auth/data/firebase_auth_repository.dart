import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';

/// The signed-in user as SportSync models it (uid + display fields).
class LocalUser {
  const LocalUser({
    required this.uid,
    required this.name,
    required this.email,
  });

  final String uid;
  final String name;
  final String email;
}

/// Firebase-backed auth: email/password sign-in, registration, password
/// reset email, and a live auth-state stream the router reacts to.
class FirebaseAuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static LocalUser? _fromFirebase(User? user) {
    if (user == null) return null;
    return LocalUser(
      uid: user.uid,
      name: user.displayName ?? (user.email?.split('@').first ?? 'Fan'),
      email: user.email ?? '',
    );
  }

  /// Emits the current user whenever auth state changes (sign-in/out, token
  /// refresh) so the whole app reacts immediately.
  Stream<LocalUser?> authStateChanges() =>
      _auth.authStateChanges().map(_fromFirebase);

  LocalUser? currentUser() => _fromFirebase(_auth.currentUser);

  /// Creates (or reuses) a device-level anonymous account so the app works
  /// without any sign-in screens while still persisting channels per install.
  Future<LocalUser> signInAnonymously() async {
    try {
      final creds = await _auth.signInAnonymously();
      return _fromFirebase(creds.user)!;
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<LocalUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fromFirebase(creds.user)!;
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<LocalUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await creds.user?.updateDisplayName(name);
      return _fromFirebase(creds.user)!;
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  /// Sends a password-reset email (the user chooses a new password via the
  /// emailed link).
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    }
  }

  /// Updates the profile. The display name is applied directly; the email is
  /// changed through Firebase Auth (a "requires-recent-login" error is mapped
  /// to a friendly message when the session is too old).
  Future<LocalUser> updateProfile({String? name, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You are not signed in.');
    }
    final trimmedName = name?.trim();
    if (trimmedName != null &&
        trimmedName.isNotEmpty &&
        trimmedName != user.displayName) {
      await user.updateDisplayName(trimmedName);
    }
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null &&
        trimmedEmail.isNotEmpty &&
        trimmedEmail != user.email) {
      try {
        // Sends a verification email to the new address; the change only
        // applies once the user confirms it.
        await user.verifyBeforeUpdateEmail(trimmedEmail);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          throw const AuthException(
            'Sign in again before changing your email address.',
          );
        }
        throw _mapAuthError(error);
      }
    }
    return _fromFirebase(_auth.currentUser)!;
  }
}

/// Maps FirebaseAuthException codes to friendly, UI-safe messages.
AppException _mapAuthError(FirebaseAuthException error) {
  final message = switch (error.code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' => 'No account found for that email.',
    'wrong-password' || 'invalid-credential' =>
      'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'That password is too weak.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Network error — check your connection.',
    'operation-not-allowed' => 'Email/password sign-in is not enabled.',
    'missing-email' => 'Please enter your email address.',
    _ => error.message ?? 'Authentication failed.',
  };
  return AuthException(message, cause: error);
}
