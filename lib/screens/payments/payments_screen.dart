import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../profile/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../shell.dart';
import 'pay_sheet.dart';
import 'receipt_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final upcoming = app.unpaidCharges;
    final today = app.today;

    // Light status-bar icons over the blue header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          const _Header(),
          // The content rises over the header on a rounded sheet.
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Segmented(
                    labels: [context.tr('upcoming'), context.tr('history')],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0) ...[
                    if (upcoming.isEmpty)
                      EmptyState(
                        icon: Icons.celebration_outlined,
                        title: context.tr('all_paid'),
                        body: context.tr('all_paid_sub'),
                      )
                    else
                      for (final c in upcoming) ...[
                        _ChargeTile(charge: c, state: c.stateOn(today)),
                        const SizedBox(height: 10),
                      ],
                  ] else ...[
                    if (app.payments.isEmpty)
                      EmptyState(icon: Icons.receipt_long_outlined, title: context.tr('no_payments'), body: '')
                    else
                      for (final p in app.payments) ...[_PaymentTile(payment: p), const SizedBox(height: 10)],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edge-to-edge blue header (after the reference design): photo, month pill
/// and bell on top, then the balance large and centred with the currency
/// lighter, a one-line context, Pay now, and three stats in a frosted panel.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final balance = app.balanceDue;
    final lease = app.lease;
    final today = DateTime(app.today.year, app.today.month, app.today.day);
    final due = app.dueCharges;
    final next = app.nextCharge;
    final goTo = ShellController.of(context).goTo;

    final formatted = context.money(balance);
    final cut = formatted.lastIndexOf(' ');
    final number = formatted.substring(0, cut);
    final unit = formatted.substring(cut);

    String subline;
    if (due.isNotEmpty) {
      final days = due.first.dueOn.difference(today).inDays;
      final when = days < 0
          ? context.tr('overdue_by', {'n': -days})
          : days == 0
          ? context.tr('due_today')
          : context.tr('due_in', {'n': days});
      subline = '${context.month(due.first.periodStart)} · $when';
    } else {
      subline = next == null ? context.tr('all_paid') : '${context.tr('upcoming')} · ${context.date(next.dueOn)}';
    }

    final thisYear = app.payments.where((p) => p.paidOn.year == app.today.year).length;

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 52),
      decoration: const BoxDecoration(gradient: AppColors.brandHeaderGradient),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(onOpenTab: goTo))),
                child: Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.25)),
                  child: ClipOval(child: AppImage(app.user.photo, fit: BoxFit.cover, cacheWidth: 150)),
                ),
              ),
              const Spacer(),
              _GlassOnBlue(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  context.month(app.today),
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: _GlassOnBlue(
                  circle: true,
                  child: SizedBox.square(
                    dimension: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded, color: AppColors.white, size: 22),
                        if (app.unreadCount > 0)
                          Positioned(
                            top: 12,
                            right: 13,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            context.tr('balance_due'),
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: number,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.8,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.5),
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(subline, style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 16),
          Material(
            color: AppColors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => showPaySheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                child: Text(
                  balance > 0 ? context.tr('pay_now') : context.tr('pay_in_advance'),
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // White stats panel under the amount.
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(color: AppColors.onyx.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Stat(
                    label: context.tr('paid_this_year'),
                    value: _amountOnly(context.money(app.paidThisYear, compact: true)),
                    caption: context.tr('payments_count', {'n': thisYear}),
                  ),
                  const _Divider(),
                  _Stat(label: context.tr('on_time_rate'), value: '100%', caption: context.tr('never_late')),
                  const _Divider(),
                  _Stat(
                    label: context.tr('monthly_rent'),
                    value: _amountOnly(context.money(lease?.rent ?? 0)),
                    caption: lease == null ? '' : context.tr('day_of_month', {'n': lease.dueDay}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted white-on-blue surface for the header's pill, bell and stats.
class _GlassOnBlue extends StatelessWidget {
  const _GlassOnBlue({required this.child, this.padding = EdgeInsets.zero, this.circle = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: 0.14),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(100),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
    ),
    child: child,
  );
}

/// "350 000 FCFA" → "350 000"; the card already reads in the agency currency.
String _amountOnly(String money) => money.substring(0, money.lastIndexOf(' '));

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const VerticalDivider(width: 1, thickness: 1, color: AppColors.line);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.caption});
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(100)),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: i == index ? AppColors.white : AppColors.muted,
                                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({required this.charge, required this.state});
  final RentCharge charge;
  final ChargeState state;

  @override
  Widget build(BuildContext context) {
    final future = charge.periodStart.isAfter(DateTime.now());
    final (label, fg, bg) = future
        ? (context.tr('upcoming'), AppColors.ink, AppColors.white)
        : switch (state) {
            ChargeState.overdue => (context.tr('overdue'), AppColors.white, AppColors.ink),
            _ => (context.tr('pending'), AppColors.ink, AppColors.white),
          };
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _DateBadge(date: charge.dueOn, highlight: !future),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.month(charge.periodStart),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
                const SizedBox(height: 4),
                StatusPill(label: label, color: fg, background: bg),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.money(charge.balance), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => showPaySheet(context, only: charge),
                child: LiquidGlass(
                  radius: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    context.tr('pay_now'),
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Day over month, black when it needs attention, grey when it can wait.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, this.highlight = false});
  final DateTime date;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final month = context.dateShort(date).split(' ').last.replaceAll('.', '').toUpperCase();
    final fg = highlight ? AppColors.white : AppColors.ink;
    return Container(
      width: 56,
      height: 60,
      decoration: BoxDecoration(
        color: highlight ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        border: highlight ? null : Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            // The day is always blue: a light azure on the black badge so it
            // stays readable, brand azure on the white one.
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.soft400 : AppColors.brand,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: fg.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// A settled payment: when it was paid, which month it covered, how, and a
/// tap through to the receipt.
class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReceiptScreen(payment: payment))),
      child: Row(
        children: [
          _DateBadge(date: payment.paidOn, highlight: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.periods.map(context.month).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
                const SizedBox(height: 4),
                Text(
                  context.methodLabel(payment.method),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(context.money(payment.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ],
      ),
    );
  }
}
