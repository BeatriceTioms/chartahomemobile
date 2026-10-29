import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Charta Home mark: a C ring around an H whose right leg holds an open
/// door with light spilling out. Same geometry as components/Logo.tsx.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 40,
    this.color = AppColors.azure800,
    this.door = AppColors.white,
    this.wedge = AppColors.soft500,
  });

  final double size;
  final Color color;
  final Color door;
  final Color wedge;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter(color, door, wedge)),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color, this.door, this.wedge);
  final Color color;
  final Color door;
  final Color wedge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..color = color;

    // C ring, open on the right: arc from (70,15.4) the long way to (70,84.6).
    final ring = Path()
      ..moveTo(70, 15.4)
      ..arcToPoint(const Offset(70, 84.6), radius: const Radius.circular(40), largeArc: true, clockwise: false);
    canvas.drawPath(
      ring,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15,
    );

    canvas.drawRect(const Rect.fromLTWH(35, 23, 11, 54), fill);
    canvas.drawRect(const Rect.fromLTWH(53, 23, 12, 61), fill);
    canvas.drawRect(const Rect.fromLTWH(43, 45, 14, 11), fill);

    canvas.drawPath(
      Path()
        ..moveTo(54, 84)
        ..lineTo(71, 84)
        ..lineTo(54, 74)
        ..close(),
      Paint()..color = wedge,
    );
    canvas.drawPath(
      Path()
        ..moveTo(55.5, 60)
        ..lineTo(63, 58.5)
        ..lineTo(63, 82.5)
        ..lineTo(55.5, 81)
        ..close(),
      Paint()..color = door,
    );
    canvas.drawCircle(const Offset(57.6, 70.5), 1.2, fill);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color || old.door != door || old.wedge != wedge;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22, this.dark = false});
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = dark ? AppColors.white : AppColors.azure800;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size * 1.5, color: c, door: dark ? AppColors.azure800 : AppColors.white),
        SizedBox(width: size * 0.4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Charta ',
                style: AppTheme.serif(size: size, color: c),
              ),
              TextSpan(
                text: 'Home',
                style: AppTheme.serif(size: size, weight: FontWeight.w400, color: c.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
