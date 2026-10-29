import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/backend.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'receipt_screen.dart';

Future<void> showPaySheet(BuildContext context, {RentCharge? only}) =>
    showAppSheet(context, expand: true, builder: (_) => PaySheet(only: only));

enum _Stage { choose, processing, done }

/// Pick periods → pick method → approve on phone → receipt.
class PaySheet extends StatefulWidget {
  const PaySheet({super.key, this.only});
  final RentCharge? only;

  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  late final List<RentCharge> _charges = context.appRead.payableCharges();
  late int _count; // how many of the oldest charges are selected
  PaymentMethod _method = PaymentMethod.mobileMoney;
  _Stage _stage = _Stage.choose;
  Payment? _payment;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.only != null) {
      _count = _charges.indexOf(widget.only!) + 1;
    } else {
      final due = context.appRead.dueCharges.length;
      _count = due == 0 ? (_charges.isEmpty ? 0 : 1) : due;
    }
  }

  List<RentCharge> get _selected => _charges.take(_count).toList();
  int get _amount => _selected.fold(0, (s, c) => s + c.balance);

  /// Rent is settled oldest first, like the SaaS allocates payments, so
  /// ticking a later month also ticks the ones before it.
  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _count = i < _count ? i : i + 1);
  }

  Future<void> _pay() async {
    setState(() {
      _stage = _Stage.processing;
      _error = null;
    });
    try {
      final payment = await context.appRead.pay(_selected, _method);
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _payment = payment;
          _stage = _Stage.done;
        });
      }
    } catch (e) {
      // Cancelled, failed or not confirmed yet on PayUnit: back to the
      // choices, with a plain explanation above the button.
      if (!mounted) return;
      setState(() {
        _stage = _Stage.choose;
        _error = context.tr(switch (e) {
          PaymentNotCompleted(outcome: PaymentOutcome.pending) => 'payment_still_pending',
          PaymentNotCompleted() => 'rent_payment_not_completed',
          BackendException(:final key) => key,
          _ => 'err_generic',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: switch (_stage) {
        _Stage.choose => _choose(),
        _Stage.processing => _processing(),
        _Stage.done => _done(),
      },
    );
  }

  Widget _choose() {
    final today = context.app.today;
    return Column(
      key: const ValueKey('choose'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              Text(context.tr('pay_rent'), style: AppTheme.serif(size: 28)),
              const SizedBox(height: 4),
              Text(
                '${context.app.lease?.property.building ?? ''} · ${context.tr('unit', {'u': context.app.lease?.unitLabel ?? ''})}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('choose_periods'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    context.tr('months_selected', {'n': _count}),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quick picks; months are always settled oldest first.
              Wrap(
                spacing: 8,
                children: [
                  for (final n in {1, 3, 6, _charges.length}.where((n) => n <= _charges.length))
                    ChoiceChipPill(
                      label: n == _charges.length && n > 6
                          ? context.tr('all')
                          : context.tr(n == 1 ? 'month_one' : 'months', {'n': n}),
                      dense: true,
                      selected: _count == n,
                      onTap: () => setState(() => _count = n),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _charges.length; i++) ...[
                _PeriodRow(
                  charge: _charges[i],
                  state: _charges[i].stateOn(today),
                  selected: i < _count,
                  onTap: () => _toggle(i),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
              Text(context.tr('choose_method'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              // The network (MTN MoMo or Orange Money) and the phone number
              // are chosen on PayUnit's hosted page, not here.
              _MethodTile(
                method: PaymentMethod.mobileMoney,
                icon: Icons.account_balance_wallet_outlined,
                subtitle: 'MTN MoMo · Orange Money',
                selected: _method == PaymentMethod.mobileMoney,
                onTap: () => setState(() => _method = PaymentMethod.mobileMoney),
              ),
              const SizedBox(height: 8),
              _MethodTile(
                method: PaymentMethod.card,
                icon: Icons.account_balance_wallet_outlined,
                subtitle: 'Visa · Mastercard',
                selected: _method == PaymentMethod.card,
                onTap: () => setState(() => _method = PaymentMethod.card),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.tr(_method == PaymentMethod.card ? 'card_hint' : 'momo_hint'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.paddingOf(context).bottom + 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              KeyValueRow(label: context.tr('fees'), value: context.tr('free')),
              KeyValueRow(label: context.tr('total'), value: context.money(_amount), bold: true),
              const SizedBox(height: 10),
              PillButton(
                color: AppColors.brand,
                icon: Icons.lock_rounded,
                label: context.tr('pay_amount', {'amount': context.money(_amount)}),
                onPressed: _count == 0 ? null : _pay,
              ),
              const SizedBox(height: 10),
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
    );
  }

  Widget _processing() {
    return Padding(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Pulse(),
          const SizedBox(height: 36),
          Text(context.tr('processing'), textAlign: TextAlign.center, style: AppTheme.serif(size: 24)),
          const SizedBox(height: 10),
          Text(
            context.tr('processing_sub'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(context.money(_amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(context.methodLabel(_method), style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _done() {
    final p = _payment!;
    return Center(
      key: const ValueKey('done'),
      child: SingleChildScrollView(
        child: SuccessView(
          title: context.tr('payment_success'),
          body: context.tr('payment_success_sub', {'agency': context.app.agencyName}),
          extra: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                KeyValueRow(label: context.tr('amount'), value: context.money(p.amount), bold: true),
                KeyValueRow(label: context.tr('reference'), value: p.reference),
              ],
            ),
          ),
          primary: context.tr('view_receipt'),
          onPrimary: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(MaterialPageRoute(builder: (_) => ReceiptScreen(payment: p)));
          },
          secondary: context.tr('done'),
          onSecondary: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.charge, required this.state, required this.selected, required this.onTap});
  final RentCharge charge;
  final ChargeState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final future = charge.periodStart.isAfter(DateTime.now());
    final label = future
        ? context.tr('upcoming')
        : context.tr(switch (state) {
            ChargeState.overdue => 'overdue',
            ChargeState.pending => 'pending',
            ChargeState.paid => 'paid',
          });
    // On the black selected row every pill is white; otherwise only
    // "overdue" is inverted so it stands out.
    // Rows stay white; selection shows only as a black checkbox, so
    // picking many months still reads calmly.
    final strong = !future && state == ChargeState.overdue;
    const fg = AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
          boxShadow: selected ? AppColors.softShadow : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? AppColors.ink : AppColors.faint, width: 1.5),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.month(charge.periodStart),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.tr('due_on')} · ${context.date(charge.dueOn)}',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.money(charge.balance),
                  style: TextStyle(fontWeight: FontWeight.w700, color: fg),
                ),
                const SizedBox(height: 4),
                StatusPill(
                  label: label,
                  color: strong ? AppColors.white : AppColors.ink,
                  background: strong ? AppColors.ink : AppColors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.icon,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final PaymentMethod method;
  final IconData icon;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          boxShadow: selected ? AppColors.liftShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.methodLabel(method),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: fg.withValues(alpha: 0.65))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
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

/// Concentric rings pulsing while PayUnit confirms the payment.
class _Pulse extends StatefulWidget {
  const _Pulse();

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 180,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (_) {
                  final t = (_c.value + i / 3) % 1;
                  return Container(
                    width: 80 + 100 * t,
                    height: 80 + 100 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.35 * (1 - t)),
                    ),
                  );
                },
              ),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: AppColors.white, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}
