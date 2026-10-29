import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _icons = {
    NoticeKind.rent: Icons.account_balance_wallet_outlined,
    NoticeKind.maintenance: Icons.handyman_outlined,
    NoticeKind.visit: Icons.event_available_outlined,
    NoticeKind.application: Icons.assignment_outlined,
    NoticeKind.agency: Icons.campaign_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('notifications')),
        actions: [
          if (app.unreadCount > 0)
            TextButton(
              onPressed: app.markAllRead,
              child: Text(
                context.tr('mark_all_read'),
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: app.notices.isEmpty
          ? EmptyState(icon: Icons.notifications_none_rounded, title: context.tr('no_notifications'), body: '')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: app.notices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = app.notices[i];
                return SurfaceCard(
                  color: n.read ? AppColors.white : AppColors.white,
                  border: n.read,
                  onTap: () => app.markRead(n),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: n.read ? AppColors.white : AppColors.ink,
                          shape: BoxShape.circle,
                          border: n.read ? Border.all(color: AppColors.line) : null,
                        ),
                        child: Icon(_icons[n.kind], color: n.read ? AppColors.ink : AppColors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(context.tr(n.title), style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr(n.body),
                              style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
                            ),
                            const SizedBox(height: 6),
                            Text(context.ago(n.at), style: const TextStyle(color: AppColors.faint, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
