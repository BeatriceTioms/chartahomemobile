import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Last step before paying a short stay: the home, the dates, who is
/// staying, the price line by line and how to pay. Nothing is charged until
/// "Confirm and pay".
class StayReviewScreen extends StatefulWidget {
  const StayReviewScreen({super.key, required this.property, required this.checkIn, required this.nights});
  final Property property;
  final DateTime checkIn;
  final int nights;

  @override
  State<StayReviewScreen> createState() => _StayReviewScreenState();
}

class _StayReviewScreenState extends State<StayReviewScreen> {
  PaymentMethod _method = PaymentMethod.mobileMoney;
  bool _busy = false;
  String? _error;
  bool _datesTaken = false;

  /// The held booking, kept so a retry pays it instead of holding twice.
  StayBooking? _held;
  bool _paid = false;

  Property get p => widget.property;
  DateTime get _checkOut => widget.checkIn.add(Duration(days: widget.nights));
  String _nightsLabel(int n) => context.tr(n == 1 ? 'night_one' : 'nights', {'n': n});

  Future<void> _confirm() async {
    final app = context.appRead;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _held ??= await app.holdStay(p, checkIn: widget.checkIn, nights: widget.nights, method: _method);
      await app.payStay(_held!, _method);
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _paid = true);
    } on StayUnavailable catch (e) {
      if (mounted) {
        setState(() {
          _datesTaken = true;
          _error = context.tr('night_taken', {'date': context.dateShort(e.night)});
        });
      }
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
      if (mounted) setState(() => _error = context.tr(e.key));
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('err_generic'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paid) return _success(_held!);
    final app = context.app;
    final quote = p.quote(widget.nights);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 42,
              onTap: _busy ? null : () => Navigator.pop(context),
            ),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('review_title')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(context.tr('review_sub'), style: const TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  ReviewErrorBanner(
                    text: _error!,
                    action: _datesTaken ? context.tr('change_dates') : null,
                    onAction: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                ],
                _Card(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: AppImage(p.cover, width: 76, height: 76, cacheWidth: 240),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.building} · ${p.address}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 15),
                                const SizedBox(width: 3),
                                Text('${p.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('  ·  ${p.agency}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: context.tr('your_stay'),
                  trailing: _busy ? null : _EditLink(onTap: () => Navigator.pop(context)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateBlock(
                              label: context.tr('check_in'),
                              date: context.weekdayDate(widget.checkIn),
                              time: context.tr('check_in_time'),
                            ),
                          ),
                          Container(width: 1, height: 52, color: AppColors.line),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DateBlock(
                              label: context.tr('check_out'),
                              date: context.weekdayDate(_checkOut),
                              time: context.tr('check_out_time'),
                            ),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                      _Line(icon: Icons.nights_stay_outlined, label: _nightsLabel(widget.nights)),
                      _Line(
                        icon: Icons.person_outline_rounded,
                        label: app.user.name.isEmpty ? context.tr('guest') : app.user.name,
                        detail: [app.user.phone, app.user.email].where((v) => v.isNotEmpty).join(' · '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: context.tr('price_details'),
                  child: Column(
                    children: [
                      KeyValueRow(
                        label: '${_nightsLabel(widget.nights)} × ${context.money(p.nightlyRate ?? 0)}',
                        value: context.money(quote.subtotal),
                      ),
                      if (quote.discount > 0)
                        KeyValueRow(
                          label: context.tr('package_saving', {'n': _nightsLabel(quote.packageNights!)}),
                          value: '− ${context.money(quote.discount)}',
                        ),
                      KeyValueRow(label: context.tr('deposit'), value: context.tr('none')),
                      KeyValueRow(label: context.tr('fees'), value: context.tr('free')),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
                      KeyValueRow(label: context.tr('total'), value: context.money(quote.total), bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: context.tr('choose_method'),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 10),
                      Text(
                        context.tr(_method == PaymentMethod.card ? 'card_hint' : 'momo_hint'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: context.tr('good_to_know'),
                  child: Column(
                    children: [
                      _Line(icon: Icons.timer_outlined, label: context.tr('hold_note', {'n': AppState.holdMinutes})),
                      _Line(icon: Icons.policy_outlined, label: context.tr('cancellation_note', {'agency': p.agency})),
                      _Line(icon: Icons.mail_outline_rounded, label: context.tr('receipt_note')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('pay_terms'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.faint, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      context.tr(_held == null ? 'holding_dates' : 'processing'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                PillButton(
                  color: AppColors.brand,
                  icon: Icons.lock_rounded,
                  loading: _busy,
                  label: context.tr(_error != null && !_datesTaken ? 'try_again_pay' : 'confirm_pay', {
                    'amount': context.money(_held?.total ?? quote.total),
                  }),
                  onPressed: _datesTaken ? null : _confirm,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.faint),
                    const SizedBox(width: 5),
                    Text(context.tr('secure_payment'), style: const TextStyle(color: AppColors.faint, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(StayBooking b) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: SuccessView(
            title: context.tr('stay_booked'),
            body: context.tr('stay_booked_sub', {
              'property': p.title,
              'from': context.dateShort(b.checkIn),
              'to': context.dateShort(b.checkOut),
              'ref': b.reference,
            }),
            extra: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  KeyValueRow(label: context.tr('stay_total'), value: context.money(b.total), bold: true),
                  KeyValueRow(label: context.tr('stay_length'), value: _nightsLabel(b.nights)),
                  KeyValueRow(label: context.tr('method'), value: context.methodLabel(_method)),
                ],
              ),
            ),
            primary: context.tr('done'),
            onPrimary: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title, this.trailing});
  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    ),
  );
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      context.tr('edit'),
      style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
    ),
  );
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.label, required this.date, required this.time});
  final String label;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
      const SizedBox(height: 4),
      Text(date, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
      const SizedBox(height: 2),
      Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, this.detail});
  final IconData icon;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w500)),
              if (detail != null && detail!.isNotEmpty)
                Text(detail!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Payment option; black with white text when chosen.
class PaymentMethodRow extends StatelessWidget {
  const PaymentMethodRow({super.key, required this.label, required this.sub, required this.selected, required this.onTap});
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 19, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  Text(sub, style: TextStyle(color: fg.withValues(alpha: 0.65), fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.white : AppColors.faint, width: selected ? 7 : 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewErrorBanner extends StatelessWidget {
  const ReviewErrorBanner({super.key, required this.text, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.ink, width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500)),
              if (action != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
