import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../theme/app_colors.dart';

/// Shimmer wrapper — sweeps a soft highlight across its child while a source
/// is being tested or a feed is loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.charcoal800 : AppColors.mist;
    final highlight = isDark ? AppColors.charcoal700 : AppColors.stone;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A rounded placeholder used inside skeletons (avatar, lines, cards).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppSizes.radiusSm,
    this.shape,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape? shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: shape != null
          ? BoxDecoration(color: Colors.white, shape: shape!)
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
            ),
    );
  }
}

/// A full skeleton match card used while a feed is fetching.
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 96, height: 12),
              SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  SkeletonBox(width: 40, height: 40, shape: BoxShape.circle),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: double.infinity, height: 14),
                        SizedBox(height: AppSizes.sm),
                        SkeletonBox(width: 140, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.lg),
              SkeletonBox(width: 180, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
