import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportsync/features/auth/data/firebase_auth_repository.dart';
import 'package:sportsync/features/auth/viewmodels/auth_view_model.dart';
import 'package:sportsync/features/profile/views/profile_screen.dart';
import 'package:sportsync/widgets/common/app_avatar.dart';

void main() {
  SharedPreferences.setMockInitialValues({
    'sportyapp.settings.themeMode': 'dark',
    'sportyapp.settings.notifications': '1|0',
  });

  Widget harness() {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: ProfileScreen()),
        ),
        GoRoute(
          path: '/profile/api',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('API Settings'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(() => _FakeAuthNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Profile renders without API settings visible', (tester) async {
    // Warm the cache so every getInstance() resolves instantly.
    await SharedPreferences.getInstance();

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Test User'), findsOneWidget);
    // No visible entry point to the hidden API settings.
    expect(find.text('Add API'), findsNothing);
    expect(find.text('API Settings'), findsNothing);
    expect(find.text('Cricket API'), findsNothing);
  });

  testWidgets('7 avatar taps within 3s unlocks Developer Mode', (tester) async {
    await SharedPreferences.getInstance();

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byType(AppAvatar));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Developer Mode Activated'), findsOneWidget);
    // Navigated to the hidden API Settings screen.
    expect(find.text('API Settings'), findsOneWidget);
  });

  testWidgets('fewer than 7 taps does nothing', (tester) async {
    await SharedPreferences.getInstance();

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(AppAvatar));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Developer Mode Activated'), findsNothing);
    expect(find.text('API Settings'), findsNothing);
  });
}

class _FakeAuthNotifier extends AuthViewModel {
  @override
  Future<LocalUser?> build() async =>
      const LocalUser(uid: 'u1', name: 'Test User', email: 'test@example.com');
}
