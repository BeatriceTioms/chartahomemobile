import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/top_bar.dart';
import 'new_ticket_screen.dart';
import 'ticket_detail_screen.dart';

const categoryIcons = <TicketCategory, IconData>{
  TicketCategory.plumbing: Icons.plumbing_rounded,
  TicketCategory.electrical: Icons.electrical_services_rounded,
  TicketCategory.appliance: Icons.kitchen_outlined,
  TicketCategory.locks: Icons.door_front_door_outlined,
  TicketCategory.pests: Icons.pest_control_outlined,
  TicketCategory.painting: Icons.format_paint_outlined,
  TicketCategory.cleaning: Icons.cleaning_services_outlined,
  TicketCategory.other: Icons.more_horiz_rounded,
};

(Color, Color) statusColors(TicketStatus s) => switch (s) {
  TicketStatus.newTicket => (AppColors.ink, AppColors.white),
  TicketStatus.assigned => (AppColors.ink, AppColors.white),
  TicketStatus.inProgress => (AppColors.ink, AppColors.white),
  TicketStatus.resolved => (AppColors.ink, AppColors.white),
  TicketStatus.cancelled => (AppColors.muted, AppColors.white),
};

void openTicket(BuildContext context, Ticket t) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t)));

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _closed = false;

  void _new([TicketCategory? category]) => Navigator.of(
    context,
  ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => NewTicketScreen(initialCategory: category)));

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final list = _closed ? app.closedTickets : app.openTickets;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 92),
        child: FloatingActionButton.extended(
          onPressed: _new,
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: const StadiumBorder(),
          icon: const Icon(Icons.add_rounded),
          label: Text(context.tr('new_request'), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
          children: [
            const TopBar(),
            const SizedBox(height: 22),
            Text(context.tr('repairs'), style: AppTheme.serif(size: 30)),
            const SizedBox(height: 4),
            Text(context.tr('repairs_sub'), style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            // One-tap shortcuts for the most common problems.
            SizedBox(
              height: 74,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final c in [
                    TicketCategory.plumbing,
                    TicketCategory.electrical,
                    TicketCategory.appliance,
                    TicketCategory.locks,
                    TicketCategory.pests,
                    TicketCategory.other,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => _new(c),
                        child: SizedBox(
                          width: 86,
                          child: LiquidGlass(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(categoryIcons[c], color: AppColors.ink, size: 22),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    context.categoryLabel(c),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                ChoiceChipPill(
                  label: '${context.tr('open')} · ${app.openTickets.length}',
                  selected: !_closed,
                  dense: true,
                  onTap: () => setState(() => _closed = false),
                ),
                const SizedBox(width: 8),
                ChoiceChipPill(
                  label: '${context.tr('closed')} · ${app.closedTickets.length}',
                  selected: _closed,
                  dense: true,
                  onTap: () => setState(() => _closed = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.handyman_outlined,
                title: context.tr('no_tickets'),
                body: context.tr('no_tickets_sub'),
              )
            else
              for (final t in list) ...[
                TicketCard(ticket: t, onTap: () => openTicket(context, t)),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final (fg, bg) = statusColors(t.status);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                child: Icon(categoryIcons[t.category], color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${t.number} · ${t.location} · ${context.ago(t.openedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              StatusPill(label: context.statusLabel(t.status), color: fg, background: bg),
            ],
          ),
          if (t.isOpen) ...[const SizedBox(height: 14), _Steps(status: t.status)],
          if (t.technician != null && t.isOpen) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Avatar(image: t.technician!.photo, name: t.technician!.name, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.visitAt != null
                          ? '${t.technician!.name.split(' ').first} · ${context.dayLabel(t.visitAt!)} ${context.time(t.visitAt!)}'
                          : t.technician!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Four-dot progress: received → assigned → in progress → resolved.
class _Steps extends StatelessWidget {
  const _Steps({required this.status});
  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final reached = switch (status) {
      TicketStatus.newTicket => 0,
      TicketStatus.assigned => 1,
      TicketStatus.inProgress => 2,
      _ => 3,
    };
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i <= reached ? AppColors.ink : AppColors.silver),
          ),
          if (i < 3)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i < reached ? AppColors.ink : AppColors.silver,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
