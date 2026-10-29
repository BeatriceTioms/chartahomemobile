import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../utils/links.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../maintenance/maintenance_screen.dart';
import '../maintenance/new_ticket_screen.dart';
import '../payments/pay_sheet.dart';
import '../../widgets/top_bar.dart';
import '../shell.dart';
import 'home_overview_card.dart';
import 'lease_screen.dart';

class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final lease = app.lease;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => context.appRead.refresh().catchError((_) {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
          children: [
            const TopBar(),
            const SizedBox(height: 22),
            Text(
              context.tr('hello', {'name': app.user.firstName}),
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(context.tr('my_home'), style: AppTheme.serif(size: 30)),
            const SizedBox(height: 20),
            if (lease == null)
              EmptyState(
                icon: Icons.home_work_outlined,
                title: context.tr('no_home_title'),
                body: context.tr('no_home_body'),
                action: context.tr('explore_homes'),
                onAction: () => ShellController.of(context).goTo(Tabs.explore),
              )
            else ...[
              HomeOverviewCard(lease: lease),
              const SizedBox(height: 16),
              const RentDueCard(),
              const SizedBox(height: 22),
              const _QuickActions(),
              const SizedBox(height: 26),
              SectionHeader(
                title: context.tr('active_repairs'),
                action: app.tickets.isEmpty ? null : context.tr('see_all'),
                onAction: () => ShellController.of(context).goTo(Tabs.repairs),
              ),
              const SizedBox(height: 12),
              if (app.openTickets.isEmpty)
                SurfaceCard(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.ink),
                      const SizedBox(width: 12),
                      Text(context.tr('no_active_repairs'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                for (final t in app.openTickets) ...[
                  TicketCard(ticket: t, onTap: () => openTicket(context, t)),
                  const SizedBox(height: 10),
                ],
            ],
            if (app.upcomingStays.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader(title: context.tr('my_stays')),
              const SizedBox(height: 12),
              for (final s in app.upcomingStays) ...[_StayTile(stay: s), const SizedBox(height: 10)],
            ],
            if (app.upcomingVisits.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader(title: context.tr('upcoming_visits')),
              const SizedBox(height: 12),
              for (final v in app.upcomingVisits) ...[_VisitTile(visit: v), const SizedBox(height: 10)],
            ],
            if (app.applications.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader(title: context.tr('applications')),
              const SizedBox(height: 12),
              for (final a in app.applications) ...[_ApplicationTile(application: a), const SizedBox(height: 10)],
            ],
            if (lease != null) ...[
              const SizedBox(height: 18),
              SectionHeader(title: context.tr('building_news')),
              const SizedBox(height: 12),
              for (final n in app.notices.where((n) => n.kind == NoticeKind.agency))
                SurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                        child: const Icon(Icons.campaign_outlined, color: AppColors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(n.body, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(context.ago(n.at), style: const TextStyle(color: AppColors.faint, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one thing a resident most often opens the app for.
class RentDueCard extends StatelessWidget {
  const RentDueCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final due = app.dueCharges;
    final balance = app.balanceDue;
    final today = DateTime(app.today.year, app.today.month, app.today.day);

    if (balance == 0) {
      final next = app.nextCharge;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.silver),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('all_paid'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    next == null
                        ? context.tr('all_paid_sub')
                        : '${context.month(next.periodStart)} · ${context.date(next.dueOn)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (next != null)
              TextButton(
                onPressed: () => showPaySheet(context),
                child: Text(
                  context.tr('pay_in_advance'),
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      );
    }

    final first = due.first;
    final days = first.dueOn.difference(today).inDays;
    final overdue = days < 0;
    final dueText = overdue
        ? context.tr('overdue_by', {'n': -days})
        : days == 0
        ? context.tr('due_today')
        : context.tr('due_in', {'n': days});

    // Compact: amount and status on the left, Pay now on the right.
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: overdue ? AppColors.white : AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    dueText,
                    maxLines: 1,
                    style: TextStyle(
                      color: overdue ? AppColors.ink : AppColors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.money(balance),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.tr('rent_due')} · ${due.length == 1 ? context.month(first.periodStart) : '${due.length} × ${context.money(first.amount)}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.75), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => showPaySheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.ink, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('pay_now'),
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.account_balance_wallet_outlined, context.tr('pay_rent'), () => showPaySheet(context)),
      (
        Icons.build_circle_outlined,
        context.tr('report_issue'),
        () => Navigator.of(
          context,
        ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const NewTicketScreen())),
      ),
      (
        Icons.description_outlined,
        context.tr('my_lease'),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaseScreen())),
      ),
      (
        Icons.support_agent_rounded,
        context.tr('contact_agency'),
        () => callNumber(context, context.app.lease?.property.agent.phone ?? ''),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in items)
          Expanded(
            child: GestureDetector(
              onTap: i.$3,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: LiquidGlass(
                      radius: 22,
                      child: Center(child: Icon(i.$1, color: AppColors.ink, size: 27)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i.$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final confirmed = visit.status == VisitStatus.confirmed;
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AppImage(visit.property.cover, width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 200),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.dayLabel(visit.at)} · ${context.time(visit.at)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          StatusPill(
            label: context.tr(confirmed ? 'visit_confirmed' : 'visit_pending'),
            color: confirmed ? AppColors.ink : AppColors.ink,
            background: AppColors.white,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application});
  final RentalApplication application;

  @override
  Widget build(BuildContext context) {
    final a = application;
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AppImage(a.property.cover, width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 200),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.tr('move_in')} · ${context.date(a.moveIn)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          StatusPill(label: context.tr('pending'), color: AppColors.ink, background: AppColors.white),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _StayTile extends StatelessWidget {
  const _StayTile({required this.stay});
  final StayBooking stay;

  @override
  Widget build(BuildContext context) {
    final s = stay;
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AppImage(s.property.cover, width: 60, height: 60, fit: BoxFit.cover, cacheWidth: 200),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.dateShort(s.checkIn)} → ${context.dateShort(s.checkOut)} · '
                  '${context.tr(s.nights == 1 ? 'night_one' : 'nights', {'n': s.nights})}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          StatusPill(label: context.tr('paid'), color: AppColors.ink, background: AppColors.white),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
