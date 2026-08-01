import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/views/forgot_password_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/viewmodels/auth_view_model.dart';
import '../features/home/views/home_screen.dart';
import '../features/live/views/live_screen.dart';
import '../features/match_details/views/match_detail_screen.dart';
import '../features/profile/about/views/about_screen.dart';
import '../features/profile/api_integrations/views/add_edit_connection_screen.dart';
import '../features/profile/api_integrations/views/api_integrations_screen.dart';
import '../features/profile/support/views/support_screen.dart';
import '../features/profile/views/profile_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/views/splash_screen.dart';
import '../models/sport_type.dart';

/// A notifier we bump whenever auth state changes so go_router re-runs its
/// redirect and sends the user to the right place automatically.
final _routerRefresh = ValueNotifier<Object?>(null);

/// go_router instance — named routes, deep-link ready, redirect-guarded.
final routerProvider = Provider<GoRouter>((ref) {
  ref.onDispose(_routerRefresh.dispose);
  ref.listen(authViewModelProvider, (_, _) => _routerRefresh.value = Object());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _routerRefresh,
    redirect: (context, state) {
      final signedIn = ref.read(authViewModelProvider).valueOrNull != null;
      final loc = state.matchedLocation;

      const public = {'/splash', '/login', '/register', '/forgot-password'};
      const authOnly = {'/login', '/register', '/forgot-password'};

      if (!signedIn) {
        if (public.contains(loc)) return null;
        return '/login';
      }
      if (authOnly.contains(loc)) return '/home';
      if (loc == '/') return '/home';
      return null;
    },
    routes: [
      // ---- Entry flow ---------------------------------------------------------
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _fadePage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _fadePage(const ForgotPasswordScreen(), state),
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
                  builder: (context, state) => const ApiIntegrationsScreen(),
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

/// Fade-through for top-level auth routes.
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
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
