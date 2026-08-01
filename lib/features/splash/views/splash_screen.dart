import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/feed_store.dart';
import '../../../theme/app_colors.dart';

/// Launch screen — the app icon photo pops in with a pulsing ring, then the
/// brand title/tagline and a determinate progress bar fade in.
///
/// Navigation is state-driven: the user stays until the initial feed has
/// resolved (value or error) so Home opens with data (never a blank/loading
/// screen). The progress bar switches to indeterminate while the feed fetches.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  /// Continuous breathing loop so the splash feels alive while the feed loads.
  late final AnimationController _breathing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  Timer? _minDuration;
  bool _minDurationElapsed = false;

  /// Safety net so a slow/unresponsive API never strands the user on the
  /// splash: Home handles its own loading/error states.
  Timer? _forceNav;

  @override
  void initState() {
    super.initState();
    // Give the entrance animation room to breathe before deciding where to go.
    _minDuration = Timer(const Duration(milliseconds: 2100), () {
      _minDurationElapsed = true;
      _decideNext();
    });
  }

  /// Heads to Home once the initial feed is ready (value or error;
  /// only after the minimum splash duration has completed.)
  void _decideNext() {
    if (!mounted) return;
    final feed = ref.read(feedStoreProvider);
    if (!(feed.hasValue || feed.hasError)) {
      // Feed still fetching — wait (bounded by _forceNav).
      _forceNav ??= Timer(const Duration(seconds: 25), () {
        if (!mounted) return;
        context.go('/home');
      });
      return;
    }

    if (!_minDurationElapsed) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _minDuration?.cancel();
    _forceNav?.cancel();
    _controller.dispose();
    _breathing.dispose();
    super.dispose();
  }

  double _clamp(double v) => v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedStoreProvider);

    // Re-evaluate the entry point whenever the feed resolves.
    ref.listen(feedStoreProvider, (_, _) => _decideNext());

    final feedReady = feed.hasValue || feed.hasError;

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
                return AnimatedBuilder(
                  animation: _breathing,
                  builder: (context, _) {
                    final t = _controller.value;
                    final breathe = Curves.easeInOut.transform(
                      _breathing.value,
                    );

                    // After the entrance animation, the user waits on the
                    // feed: the determinate bar switches to indeterminate
                    // until the data lands.
                    final waitingForData = t >= 1.0 && !feedReady;

                    // Staggered sub-animations for a polished entrance.
                    final iconFade = Curves.easeIn.transform(
                      _clamp(Interval(0.0, 0.55).transform(t)),
                    );
                    final iconPop = 0.6 +
                        0.4 *
                            Curves.easeOutBack.transform(
                              _clamp(Interval(0.0, 0.7).transform(t)),
                            );
                    final rise =
                        -18 * (1 - _clamp(Interval(0.0, 0.4).transform(t)));
                    final ringScale =
                        1.0 + 0.16 * _clamp(Interval(0.0, 0.8).transform(t));
                    final ringFade =
                        0.5 * (1 - _clamp(Interval(0.0, 0.8).transform(t)));
                    final textFade = Curves.easeOut.transform(
                      _clamp(Interval(0.35, 0.85).transform(t)),
                    );

                    // Looping "alive" layer: halo pulse, gentle bob + glow.
                    final haloScale = 1.0 + 0.09 * breathe;
                    final haloOpacity = 0.4 * breathe * iconFade;
                    final bob = 3 * (breathe - 0.5);
                    final textGlow = 0.82 + 0.18 * breathe;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App icon with a pulsing halo + breathing bob.
                        Transform.translate(
                          offset: Offset(0, rise + bob),
                          child: SizedBox(
                            width: 148,
                            height: 148,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: haloOpacity,
                                  child: Transform.scale(
                                    scale: haloScale,
                                    child: Container(
                                      width: 132,
                                      height: 132,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: ringFade,
                                  child: Transform.scale(
                                    scale: ringScale,
                                    child: Container(
                                      width: 148,
                                      height: 148,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.55),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: iconFade,
                                  child: Transform.scale(
                                    scale: iconPop,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 40,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/icon.png',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.xxxl),
                        // Title + tagline fade in, then gently shimmer.
                        Opacity(
                          opacity: textFade * textGlow,
                          child: Column(
                            children: [
                              Text(
                                AppStrings.splashWelcome,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                AppStrings.appTagline,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xxxl * 2),
                        // Determinate progress while animating; indeterminate
                        // while waiting for the initial feed.
                        SizedBox(
                          width: 120,
                          child: LinearProgressIndicator(
                            value: waitingForData ? null : t,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            color: AppColors.floodlightGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (waitingForData) ...[
                          const SizedBox(height: AppSizes.lg),
                          const Text(
                            'Loading your channels…',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
