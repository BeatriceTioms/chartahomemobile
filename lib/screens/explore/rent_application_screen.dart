import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/month_calendar.dart';
import 'stay_review_screen.dart' show PaymentMethodRow, ReviewErrorBanner;

/// One short page: the resident picks a move-in date and how long they want
/// to stay, then pays the first month and the deposit to book it. We already
/// know who they are, so nothing else is asked; the agency gets back to them
/// to sign the lease. A home whose lease has no end date can only be asked
/// for (no payment): the agency has to say when it frees up.
class RentApplicationScreen extends StatefulWidget {
  const RentApplicationScreen({super.key, required this.property});
  final Property property;

  @override
  State<RentApplicationScreen> createState() => _RentApplicationScreenState();
}

class _RentApplicationScreenState extends State<RentApplicationScreen> {
  late DateTime _moveIn = _firstDay;
  int _months = 12;
  bool _busy = false;
  bool _done = false;
  bool _paid = false;
  String? _error;
  PaymentMethod _method = PaymentMethod.mobileMoney;

  /// The hold, kept so a retry pays it instead of booking twice.
  LeaseHold? _hold;

  Property get p => widget.property;

  /// First day the agency lets the lease start (its "available from" date,
  /// skipping any nights it has closed).
  DateTime get _firstDay {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day);
    if (p.availableFrom.isAfter(d)) d = DateTime(p.availableFrom.year, p.availableFrom.month, p.availableFrom.day);
    while (!context.appRead.canMoveIn(p, d)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  bool get _canPay => p.availabilityKnown;

  Future<void> _send() async {
    setState(() => _busy = true);
    await context.appRead.apply(p, moveIn: _moveIn, months: _months);
    if (mounted) setState(() => _done = true);
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.appRead.bookLease(
        p,
        moveIn: _moveIn,
        months: _months,
        method: _method,
        hold: _hold,
        onHeld: (h) => _hold = h,
      );
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _paid = true);
    } on PaymentNotCompleted catch (e) {
      if (mounted) {
        setState(
          () => _error = context.tr(
            e.outcome == PaymentOutcome.pending ? 'payment_still_pending' : 'payment_not_completed',
            {'n': AppState.holdMinutes},
          ),
        );
      }
    } on BackendException catch (e) {
      _hold = null;
      if (mounted) setState(() => _error = context.tr(e.key));
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('err_generic'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paid) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: SuccessView(
              title: context.tr('booking_done'),
              body: context.tr('booking_done_sub', {'agency': p.agency, 'date': context.date(_moveIn)}),
              primary: context.tr('done'),
              onPrimary: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
        ),
      );
    }
    if (_done) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: SuccessView(
              title: context.tr('application_sent'),
              body: context.tr('application_sent_sub', {'agency': p.agency}),
              primary: context.tr('done'),
              onPrimary: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.close_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr(_canPay ? 'book_title' : 'rent_title')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: AppImage(p.cover, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 200),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                          const SizedBox(height: 2),
                          Text(p.address, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            '${context.money(p.rent)}${context.tr('per_month')}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.occupied || !p.availabilityKnown) ...[
                  const SizedBox(height: 16),
                  _Note(
                    icon: Icons.event_outlined,
                    text: p.availabilityKnown
                        ? context.tr('occupied_until', {'date': context.date(p.availableFrom)})
                        : context.tr('ask_agency_date', {'agency': p.agency}),
                  ),
                ],
                if (_error != null) ...[const SizedBox(height: 16), ReviewErrorBanner(text: _error!)],
                const SizedBox(height: 26),
                Text(context.tr('move_in'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: MonthCalendar(
                    firstDate: _firstDay,
                    selected: _moveIn,
                    isUnavailable: (d) => !context.appRead.canMoveIn(p, d),
                    onSelected: (d) => setState(() => _moveIn = d),
                  ),
                ),
                const SizedBox(height: 24),
                Text(context.tr('duration'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in [3, 6, 12, 24])
                      ChoiceChipPill(
                        label: context.tr('months', {'n': m}),
                        selected: _months == m,
                        onTap: () => setState(() => _months = m),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_canPay) ...[
                  Text(context.tr('to_pay_now'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        KeyValueRow(label: context.tr('first_month'), value: context.money(p.rent)),
                        KeyValueRow(label: context.tr('deposit'), value: context.money(p.deposit)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
                        KeyValueRow(label: context.tr('total'), value: context.money(p.bookingAmount), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(context.tr('choose_method'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  PaymentMethodRow(
                    label: context.tr('mobile_money'),
                    sub: 'MTN MoMo · Orange Money',
                    selected: _method == PaymentMethod.mobileMoney,
                    onTap: _busy ? null : () => setState(() => _method = PaymentMethod.mobileMoney),
                  ),
                  const SizedBox(height: 8),
                  PaymentMethodRow(
                    label: context.tr('card_short'),
                    sub: 'Visa · Mastercard',
                    selected: _method == PaymentMethod.card,
                    onTap: _busy ? null : () => setState(() => _method = PaymentMethod.card),
                  ),
                  const SizedBox(height: 20),
                  _Note(icon: Icons.timer_outlined, text: context.tr('booking_hold_note', {'n': AppState.holdMinutes})),
                  const SizedBox(height: 8),
                  _Note(icon: Icons.info_outline_rounded, text: context.tr('booking_note', {'agency': p.agency})),
                ] else
                  _Note(
                    icon: Icons.info_outline_rounded,
                    text: context.tr('agency_will_confirm', {'agency': p.agency}),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: PillButton(
                color: AppColors.brand,
                icon: _canPay ? Icons.lock_outline_rounded : null,
                label: _canPay
                    ? context.tr('pay_amount', {'amount': context.money(p.bookingAmount)})
                    : '${context.tr('submit_application')} · ${context.dateShort(_moveIn)}',
                loading: _busy,
                onPressed: _canPay ? _pay : _send,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.45)),
        ),
      ],
    ),
  );
}
