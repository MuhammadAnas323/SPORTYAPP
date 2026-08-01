import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/views/home_screen.dart';
import '../features/live/views/live_screen.dart';
import '../features/match_details/views/match_detail_screen.dart';
import '../features/profile/about/views/about_screen.dart';
import '../features/profile/api_integrations/views/add_edit_connection_screen.dart';
import '../features/profile/api_integrations/views/api_integrations_screen.dart';
import '../features/profile/api_integrations/views/api_type_picker_screen.dart';
import '../features/profile/support/views/support_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/views/splash_screen.dart';
import '../models/sport_type.dart';

/// go_router instance — named routes, deep-link ready.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/') return '/home';
      return null;
    },
    routes: [
      // ---- Entry flow ---------------------------------------------------------
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ---- Match detail (full-screen overlay, shared-axis feel) ----------------
      GoRoute(
        path: '/match/:connectionId/:providerId',
        pageBuilder: (context, state) => _sharedAxisPage(
          MatchDetailScreen(
            connectionId: state.pathParameters['connectionId']!,
            providerId: state.pathParameters['providerId']!,
          ),
          state,
        ),
      ),

      // ---- Main shell ----------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => _fadeThroughPage(
                const HomeScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/live',
              pageBuilder: (context, state) => _fadeThroughPage(
                const LiveScreen(),
                state,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => _fadeThroughPage(
                const ProfileScreen(),
                state,
              ),
              routes: [
                GoRoute(
                  path: 'api',
                  builder: (context, state) => const ApiTypePickerScreen(),
                ),
                GoRoute(
                  path: 'api/cricket',
                  builder: (context, state) =>
                      const ApiIntegrationsScreen(sportType: SportType.cricket),
                ),
                GoRoute(
                  path: 'api/football',
                  builder: (context, state) =>
                      const ApiIntegrationsScreen(sportType: SportType.football),
                ),
                GoRoute(
                  path: 'api/add',
                  builder: (context, state) => AddEditConnectionScreen(
                    initialSportType: switch (
                      state.uri.queryParameters['sport']) {
                      'football' => SportType.football,
                      'cricket' => SportType.cricket,
                      _ => null,
                    },
                  ),
                ),
                GoRoute(
                  path: 'api/edit/:id',
                  builder: (context, state) => AddEditConnectionScreen(
                    connectionId: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: 'about',
                  builder: (context, state) => const AboutScreen(),
                ),
                GoRoute(
                  path: 'support',
                  builder: (context, state) => const SupportScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Shared-axis-ish transition for detail routes (vertical + fade).
CustomTransitionPage<void> _sharedAxisPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Fade-through for shell tabs (avoids the default platform slide between tabs).
CustomTransitionPage<void> _fadeThroughPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
