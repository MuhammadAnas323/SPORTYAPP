import 'package:flutter/material.dart';

/// The custom sport icon set — drawn as painters so no font/assets are needed.
///
/// Icons: bat, ball, wicket, football, boundary, trophy. All accept a [color]
/// and render at the parent's constraints.
enum SportIconName { bat, ball, wicket, football, boundary, trophy }

class SportIcon extends StatelessWidget {
  const SportIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 20,
  });

  final SportIconName icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SportIconPainter(icon, resolved),
      ),
    );
  }
}

class _SportIconPainter extends CustomPainter {
  _SportIconPainter(this.icon, this.color);

  final SportIconName icon;
  final Color color;

  static final Paint _fill = Paint()..style = PaintingStyle.fill;
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    _fill.color = color;
    _stroke.color = color;
    final s = size.shortestSide;

    switch (icon) {
      case SportIconName.bat:
        _paintBat(canvas, s);
      case SportIconName.ball:
        _paintBall(canvas, s);
      case SportIconName.wicket:
        _paintWicket(canvas, s);
      case SportIconName.football:
        _paintFootball(canvas, s);
      case SportIconName.boundary:
        _paintBoundary(canvas, s);
      case SportIconName.trophy:
        _paintTrophy(canvas, s);
    }
  }

  void _paintBat(Canvas canvas, double s) {
    final blade = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.30, s * 0.08, s * 0.42, s * 0.58),
      const Radius.circular(3),
    );
    canvas.drawRRect(blade, _fill);
    // Shoulder.
    final shoulder = Rect.fromLTWH(s * 0.34, s * 0.60, s * 0.34, s * 0.10);
    canvas.drawRect(shoulder, _fill);
    // Handle with grip lines.
    canvas.drawRect(
      Rect.fromLTWH(s * 0.40, s * 0.70, s * 0.22, s * 0.22),
      _fill,
    );
    _stroke.strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = s * (0.73 + i * 0.065);
      canvas.drawLine(
        Offset(s * 0.40, y),
        Offset(s * 0.62, y),
        _stroke,
      );
    }
    _stroke.strokeWidth = 1.6;
  }

  void _paintBall(Canvas canvas, double s) {
    final center = Offset(s / 2, s / 2);
    final radius = s * 0.38;
    _fill.color = color;
    canvas.drawCircle(center, radius, _fill);
    // Seam.
    _stroke.color = Colors.white;
    _stroke.strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.9,
      1.8,
      false,
      _stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.55),
      2.1,
      1.8,
      false,
      _stroke,
    );
    _stroke.color = color;
    _stroke.strokeWidth = 1.6;
  }

  void _paintWicket(Canvas canvas, double s) {
    // Three stumps.
    final stumpW = s * 0.06;
    final top = s * 0.30;
    final bottom = s * 0.88;
    for (var i = 0; i < 3; i++) {
      final x = s * (0.24 + i * 0.26);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, stumpW, bottom - top),
          const Radius.circular(1),
        ),
        _fill,
      );
    }
    // Bails.
    _stroke.strokeWidth = s * 0.035;
    canvas.drawLine(
      Offset(s * 0.20, top + s * 0.04),
      Offset(s * 0.48, top + s * 0.04),
      _stroke,
    );
    canvas.drawLine(
      Offset(s * 0.52, top + s * 0.04),
      Offset(s * 0.80, top + s * 0.04),
      _stroke,
    );
    _stroke.strokeWidth = 1.6;
  }

  void _paintFootball(Canvas canvas, double s) {
    final center = Offset(s / 2, s / 2);
    final radius = s * 0.40;
    canvas.drawCircle(center, radius, _fill);

    // Simplified black pentagon + seam lines.
    _stroke.color = Colors.white;
    _stroke.strokeWidth = 1.1;
    final pent = Path()
      ..moveTo(s * 0.5, s * 0.28)
      ..lineTo(s * 0.70, s * 0.40)
      ..lineTo(s * 0.63, s * 0.64)
      ..lineTo(s * 0.37, s * 0.64)
      ..lineTo(s * 0.30, s * 0.40)
      ..close();
    canvas.drawPath(pent, _stroke);
    for (final angle in [0.0, 1.2566, 2.5133]) {
      canvas.drawLine(
        Offset(s * 0.5, s * 0.5),
        center + Offset.fromDirection(angle, s * 0.42),
        _stroke,
      );
      canvas.drawLine(
        Offset(s * 0.5, s * 0.5),
        center + Offset.fromDirection(angle + 3.14159, s * 0.42),
        _stroke,
      );
    }
    _stroke.color = color;
    _stroke.strokeWidth = 1.6;
  }

  void _paintBoundary(Canvas canvas, double s) {
    // Arc of rope + small flag.
    _stroke.strokeWidth = s * 0.045;
    canvas.drawArc(
      Rect.fromLTWH(s * 0.08, s * 0.22, s * 0.84, s * 0.70),
      0.1,
      3.4,
      false,
      _stroke,
    );
    // Flag pole.
    canvas.drawLine(
      Offset(s * 0.30, s * 0.86),
      Offset(s * 0.30, s * 0.24),
      _stroke,
    );
    _fill.color = color;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.30, s * 0.24)
        ..lineTo(s * 0.54, s * 0.33)
        ..lineTo(s * 0.30, s * 0.42)
        ..close(),
      _fill,
    );
    _stroke.strokeWidth = 1.6;
  }

  void _paintTrophy(Canvas canvas, double s) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.30, s * 0.20, s * 0.40, s * 0.34),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, _fill);
    // Handles.
    _stroke.strokeWidth = s * 0.035;
    canvas.drawArc(
      Rect.fromLTWH(s * 0.10, s * 0.28, s * 0.24, s * 0.30),
      1.6,
      2.6,
      false,
      _stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.66, s * 0.28, s * 0.24, s * 0.30),
      0.35,
      2.6,
      false,
      _stroke,
    );
    _stroke.strokeWidth = 1.6;
    // Stem + base.
    canvas.drawRect(
      Rect.fromLTWH(s * 0.46, s * 0.54, s * 0.08, s * 0.16),
      _fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.30, s * 0.70, s * 0.40, s * 0.10),
        const Radius.circular(2),
      ),
      _fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SportIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
