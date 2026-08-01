import 'package:flutter/material.dart';

import '../../models/sport_type.dart';

/// Gradient avatar for teams/users. When a [logoUrl] is provided it is loaded
/// (best-effort), otherwise the team code is rendered on a brand gradient.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.label = '?',
    this.logoUrl,
    this.sportType = SportType.cricket,
    this.size = 44,
  });

  final String label;
  final String? logoUrl;
  final SportType sportType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final seed = _seedFrom(label);
    final gradient = sportType == SportType.football
        ? const [Color(0xFF1B9A63), Color(0xFF0B4D30)]
        : [seed.color1, seed.color2];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                logoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _code(),
              ),
            )
          : _code(),
    );
  }

  Widget _code() {
    return Text(
      label.length <= 3 ? label.toUpperCase() : label.substring(0, 3).toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  static _Seed _seedFrom(String value) {
    final list = const [
      _Seed(Color(0xFF1B9A63), Color(0xFF0B4D30)),
      _Seed(Color(0xFF2563EB), Color(0xFF1E3A8A)),
      _Seed(Color(0xFFF59E0B), Color(0xFFB45309)),
      _Seed(Color(0xFFEF4444), Color(0xFF991B1B)),
      _Seed(Color(0xFF8B5CF6), Color(0xFF5B21B6)),
      _Seed(Color(0xFF0EA5E9), Color(0xFF0369A1)),
      _Seed(Color(0xFF8A5A33), Color(0xFF5C3A1E)),
      _Seed(Color(0xFF10B981), Color(0xFF065F46)),
    ];
    var hash = 0;
    for (final c in value.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return list[hash % list.length];
  }
}

class _Seed {
  const _Seed(this.color1, this.color2);
  final Color color1;
  final Color color2;
}

/// A horizontal "vs" separator used on match cards.
class VsDivider extends StatelessWidget {
  const VsDivider({super.key, this.live = false});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = live ? const Color(0xFFE53950) : scheme.onSurfaceVariant;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
      ),
      child: Text(
        'VS',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
