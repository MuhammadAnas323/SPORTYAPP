import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../widgets/animations/animated_bottom_nav.dart';

/// The app's main frame: [StatefulNavigationShell] body + animated bottom nav.
///
/// The bottom nav hides while the user scrolls a tab and slides back in 2s
/// after scrolling stops (or as soon as a tab is selected).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Minimum cumulative scroll distance (px) before the nav hides, so tiny
  /// drags and overscroll bounce don't flicker it.
  static const double _scrollHideThreshold = 24;

  Timer? _hideTimer;
  bool _navVisible = true;
  double _scrolledSinceLastShow = 0;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      _scrolledSinceLastShow += notification.scrollDelta ?? 0;
    }
    if (_scrolledSinceLastShow.abs() < _scrollHideThreshold) {
      return false;
    }

    _scrolledSinceLastShow = 0;
    _hideTimer?.cancel();
    if (_navVisible) {
      setState(() => _navVisible = false);
    }
    _hideTimer = Timer(const Duration(seconds: 2), _showNav);
    return false;
  }

  void _showNav() {
    _hideTimer?.cancel();
    if (_navVisible) return;
    setState(() => _navVisible = true);
  }

  void _onTap(int index) {
    _showNav();
    // Re-tapping the current tab pops back to its root (nice UX).
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
      return;
    }
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.navigationShell,
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedSlide(
        offset: _navVisible ? Offset.zero : const Offset(0, 1.3),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(0, 0, 0, AppSizes.sm),
          child: AnimatedBottomNav(
            currentIndex: widget.navigationShell.currentIndex,
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
      ),
    );
  }
}
