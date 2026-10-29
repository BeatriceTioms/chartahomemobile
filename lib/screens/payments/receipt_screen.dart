import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/logo.dart';

/// Rent receipt (quittance), laid out like the one the SaaS emails.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final lease = app.lease;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('receipt')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  child: Column(
                    children: [
                      const LogoMark(size: 46),
                      const SizedBox(height: 14),
                      Text(app.agencyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 18),
                      Text(
                        context.money(payment.amount),
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      StatusPill(label: context.tr('paid'), color: AppColors.ink, background: AppColors.white),
                    ],
                  ),
                ),
                const _Perforation(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                  child: Column(
                    children: [
                      KeyValueRow(label: context.tr('receipt_no'), value: payment.id.toUpperCase()),
                      KeyValueRow(label: context.tr('reference'), value: payment.reference),
                      KeyValueRow(
                        label: context.tr('date'),
                        value: '${context.date(payment.paidOn)} · ${context.time(payment.paidOn)}',
                      ),
                      KeyValueRow(label: context.tr('method'), value: context.methodLabel(payment.method)),
                      KeyValueRow(label: context.tr('period'), value: payment.periods.map(context.month).join(', ')),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      KeyValueRow(label: context.tr('tenant'), value: app.user.name),
                      if (lease != null)
                        KeyValueRow(
                          label: context.tr('property'),
                          value:
                              '${lease.property.building}\n${context.tr('unit', {'u': lease.unitLabel})} · ${lease.property.address}',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PillButton(
            icon: Icons.ios_share_rounded,
            label: context.tr('share_receipt'),
            onPressed: () => toast(context, 'PDF · ${payment.reference}', icon: Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -12, top: 0, child: _notch()),
          Positioned(right: -12, top: 0, child: _notch()),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: LayoutBuilder(
                builder: (_, c) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    (c.maxWidth / 10).floor(),
                    (_) => Container(width: 5, height: 1.5, color: AppColors.line),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notch() => Container(
    width: 24,
    height: 24,
    decoration: const BoxDecoration(color: AppColors.canvas, shape: BoxShape.circle),
  );
}
