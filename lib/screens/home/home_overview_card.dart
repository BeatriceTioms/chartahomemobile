import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'lease_screen.dart';

/// Frosted overview card (reference design): an animated ring showing how
/// far into the lease the resident is, beside three live facts about the
/// home. Replaces the static building photo.
class HomeOverviewCard extends StatelessWidget {
  const HomeOverviewCard({super.key, required this.lease});
  final Lease lease;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final now = DateTime.now();
    final end = lease.endsOn;
    final total = end == null ? 12 : (end.year - lease.startsOn.year) * 12 + end.month - lease.startsOn.month + 1;
    final done = ((now.year - lease.startsOn.year) * 12 + now.month - lease.startsOn.month + 1).clamp(0, total);
    final progress = total == 0 ? 0.0 : done / total;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaseScreen())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.12),
              blurRadius: 32,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
          ],
          // Charta palette only: white into sky (soft200/azure100), with the
          // logo's aqua (soft500) catching the bottom-right corner.
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.45, 1],
            colors: [AppColors.white, AppColors.soft200, Color(0xFFC4E7EC)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              // Two fine concentric rings echo the progress ring and add
              // depth without clutter.
              const Positioned(right: -60, top: -110, child: _Halo(size: 190)),
              const Positioned(right: -20, top: -70, child: _Halo(size: 110)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lease.property.building,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr('unit', {'u': lease.unitLabel})} · ${lease.property.address}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _LeaseRing(progress: progress, caption: context.tr('lease_progress', {'n': done, 'm': total})),
                        const SizedBox(width: 14),
                        Container(width: 1, height: 150, color: AppColors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              _Fact(
                                icon: Icons.account_balance_wallet_outlined,
                                value: context.money(app.paidThisYear, compact: true),
                                label: context.tr('paid_this_year'),
                              ),
                              const SizedBox(height: 14),
                              _Fact(
                                icon: Icons.handyman_outlined,
                                value: '${app.openTickets.length}',
                                label: context.tr('open_repairs'),
                              ),
                              const SizedBox(height: 14),
                              _Fact(
                                icon: Icons.event_outlined,
                                value: end == null ? '—' : context.dateShort(end),
                                label: context.tr('lease_ends'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.white.withValues(alpha: 0.7), width: 1.2),
    ),
  );
}

/// White track with a blue arc, a blue disc in the middle and a light knob
/// at the arc's end. Fills in when the card appears.
class _LeaseRing extends StatelessWidget {
  const _LeaseRing({required this.progress, required this.caption});
  final double progress;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox.square(
        dimension: 150,
        child: CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.azure600, AppColors.azure800],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${(v * 100).round()}',
                          style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(
                          text: '%',
                          style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text(caption, style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 10.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const stroke = 12.0;
    final r = size.width / 2 - stroke / 2 - 2;
    canvas.drawCircle(c, r + stroke / 2 + 2, Paint()..color = AppColors.white);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final sweep = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [AppColors.soft500, AppColors.azure600, AppColors.azure800],
          // Start the gradient a little before the arc so the round start
          // cap is aqua rather than wrapping to the dark end colour.
          transform: GradientRotation(-math.pi / 2 - 0.2),
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      final a = -math.pi / 2 + sweep;
      final knob = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(knob, 9, Paint()..color = AppColors.white);
      canvas.drawCircle(knob, 6, Paint()..color = AppColors.soft500);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.brand.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.azure800),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}
