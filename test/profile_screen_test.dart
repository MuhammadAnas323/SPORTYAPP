import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportsync/features/auth/data/firebase_auth_repository.dart';
import 'package:sportsync/features/auth/viewmodels/auth_view_model.dart';
import 'package:sportsync/features/profile/views/profile_screen.dart';

/// Reproduces the reported crash: ProfileScreen first build happens after
/// SharedPreferences is already warm (cached instance), which used to modify a
/// provider synchronously inside build().
void main() {
  testWidgets('ProfileScreen renders without crashing with warm prefs',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'sportyapp.settings.themeMode': 'dark',
      'sportyapp.settings.notifications': '1|0',
    });
    // Warm the cache so every getInstance() resolves instantly.
    await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    // Let the async restore microtasks + first frames run.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Add API'), findsOneWidget);
  });

  testWidgets('ProfileScreen fits a narrow phone without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'sportyapp.settings.themeMode': 'dark',
      'sportyapp.settings.notifications': '1|0',
    });
    await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthNotifier extends AuthViewModel {
  @override
  Future<LocalUser?> build() async =>
      const LocalUser(uid: 'u1', name: 'Test User', email: 'test@example.com');
}
