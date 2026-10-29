import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../utils/links.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class LeaseScreen extends StatelessWidget {
  const LeaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lease = context.app.lease!;
    final p = lease.property;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('my_lease')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AppImage(
              p.photos.length > 1 ? p.photos[1] : p.cover,
              height: 170,
              fit: BoxFit.cover,
              cacheWidth: 900,
            ),
          ),
          const SizedBox(height: 18),
          Text(p.building, style: AppTheme.serif(size: 26)),
          const SizedBox(height: 4),
          Text(
            '${context.tr('unit', {'u': lease.unitLabel})} · ${p.address}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                KeyValueRow(label: context.tr('monthly_rent'), value: context.money(lease.rent)),
                KeyValueRow(label: context.tr('deposit'), value: context.money(lease.deposit)),
                KeyValueRow(label: context.tr('due_day'), value: context.tr('day_of_month', {'n': lease.dueDay})),
                KeyValueRow(label: context.tr('duration'), value: context.cycleLabel(lease.cycle)),
                KeyValueRow(label: context.tr('move_in'), value: context.date(lease.startsOn)),
                if (lease.endsOn != null)
                  KeyValueRow(label: context.tr('lease_ends'), value: context.date(lease.endsOn!)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(title: context.tr('documents')),
          const SizedBox(height: 12),
          for (final d in const [
            (Icons.description_outlined, 'lease_agreement'),
            (Icons.fact_check_outlined, 'inventory_report'),
            (Icons.receipt_long_outlined, 'rent_receipts'),
          ]) ...[
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => toast(context, context.tr(d.$2), icon: Icons.picture_as_pdf_rounded),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                    child: Icon(d.$1, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(context.tr(d.$2), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.download_rounded, color: AppColors.faint),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SectionHeader(title: context.tr('your_agent')),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Avatar(image: p.agent.photo, name: p.agent.name, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.agent.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(p.agency, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                CircleAction(
                  icon: Icons.call_rounded,
                  size: 44,
                  color: AppColors.white,
                  background: AppColors.ink,
                  onTap: () => callNumber(context, p.agent.phone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
