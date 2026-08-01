import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../widgets/animations/animated_bottom_nav.dart';

/// The app's main frame: [StatefulNavigationShell] body + animated bottom nav.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // Re-tapping the current tab pops back to its root (nice UX).
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
      return;
    }
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(0, 0, 0, AppSizes.sm),
        child: AnimatedBottomNav(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: [
            AnimatedNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
            ),
            AnimatedNavDestination(
              icon: Icons.sensors_outlined,
              selectedIcon: Icons.sensors_rounded,
              label: 'Live',
            ),
            AnimatedNavDestination(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
