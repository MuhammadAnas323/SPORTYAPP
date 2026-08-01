import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/sport_icon.dart';

/// Launch screen — animated monogram + gradient background.
///
/// After the animation completes it navigates to the correct entry point
/// (onboarding → login → shell) based on persisted state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  Timer? _navigator;

  @override
  void initState() {
    super.initState();
    // Give the animation room to breathe before moving on.
    _navigator = Timer(const Duration(milliseconds: 1900), _decideNext);
  }

  void _decideNext() {
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _navigator?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.pitchGreen, AppColors.deepGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_controller.value);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouncing logo medallion.
                    Transform.translate(
                      offset: Offset(0, -20 * (1 - t)),
                      child: Transform.scale(
                        scale: 0.7 + t * 0.3,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const SportIcon(
                            SportIconName.trophy,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxxl),
                    // Title + tagline fade in.
                    Opacity(
                      opacity: t,
                      child: Column(
                        children: [
                          Text(
                            AppStrings.appName,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            AppStrings.appTagline,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxxl * 2),
                    // Progress shimmer.
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: AppColors.floodlightGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
