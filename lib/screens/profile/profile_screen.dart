import 'package:flutter/material.dart';

import '../../services/notifications.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../backend/backend.dart';
import '../../utils/format.dart';
import '../../utils/links.dart';
import '../../widgets/common.dart';
import '../../widgets/property_cards.dart';
import '../explore/property_detail_screen.dart';
import '../home/lease_screen.dart';
import '../shell.dart';
import 'notifications_screen.dart';

/// Opened from the photo in the top bar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onOpenTab});

  /// Switches the shell tab underneath, since this page sits above it.
  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final lease = app.lease;

    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return _SubPage(
      title: context.tr('profile'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SurfaceCard(
            child: Row(
              children: [
                Avatar(image: app.user.photo, size: 68, ring: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.user.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(app.user.phone, style: const TextStyle(color: AppColors.muted)),
                      if (lease != null) ...[
                        const SizedBox(height: 8),
                        StatusPill(
                          label: '${lease.property.building} · ${lease.unitLabel}',
                          color: AppColors.ink,
                          background: AppColors.white,
                          dot: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Counter(
                value: '${app.savedProperties.length}',
                label: context.tr('saved_homes'),
                onTap: () => push(const SavedScreen()),
              ),
              const SizedBox(width: 10),
              _Counter(
                value: '${app.upcomingVisits.length}',
                label: context.tr('my_visits'),
                onTap: () => push(const VisitsScreen()),
              ),
              const SizedBox(width: 10),
              _Counter(
                value: '${app.payments.length}',
                label: context.tr('rent_receipts'),
                onTap: () {
                  Navigator.pop(context);
                  onOpenTab?.call(Tabs.pay);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Group(
            children: [
              _Row(
                icon: Icons.person_outline_rounded,
                label: context.tr('personal_info'),
                onTap: () => toast(context, app.user.email),
              ),
              if (lease != null)
                _Row(
                  icon: Icons.description_outlined,
                  label: context.tr('my_lease'),
                  onTap: () => push(const LeaseScreen()),
                ),
              _Row(
                icon: Icons.notifications_none_rounded,
                label: context.tr('notifications'),
                trailing: app.unreadCount > 0 ? '${app.unreadCount}' : null,
                onTap: () => push(const NotificationsScreen()),
              ),
              _SwitchRow(
                icon: Icons.campaign_outlined,
                label: context.tr('news_setting'),
                sub: context.tr('news_setting_sub'),
                value: app.newsEnabled && app.notificationsEnabled,
                onChanged: (on) async {
                  if (on && !app.notificationsEnabled) {
                    var granted = false;
                    try {
                      granted = await NotificationService.instance.requestPermission();
                    } catch (_) {}
                    app.setNotificationsEnabled(granted);
                  }
                  app.setNewsEnabled(on);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Group(
            children: [
              _Row(
                icon: Icons.translate_rounded,
                label: context.tr('language'),
                trailing: app.lang == 'fr' ? 'Français' : 'English',
                onTap: () => app.setLang(app.lang == 'fr' ? 'en' : 'fr'),
              ),
              _Row(icon: Icons.help_outline_rounded, label: context.tr('help'), onTap: () => emailSupport(context)),
              _Row(
                icon: Icons.shield_outlined,
                label: context.tr('privacy_policy'),
                onTap: () => openLegal(context, 'privacy'),
              ),
              _Row(
                icon: Icons.article_outlined,
                label: context.tr('terms_of_use'),
                onTap: () => openLegal(context, 'terms'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Group(
            children: [
              _Row(
                icon: Icons.logout_rounded,
                label: context.tr('sign_out'),
                danger: true,
                onTap: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  app.signOut();
                },
              ),
              _Row(
                icon: Icons.delete_outline_rounded,
                label: context.tr('delete_account'),
                danger: true,
                onTap: () => showAppSheet<void>(context, builder: (_) => const _DeleteAccountSheet()),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(context.tr('app_version'), style: const TextStyle(color: AppColors.faint, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label, required this.onTap});
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      radius: AppRadius.md,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.only(left: 64), child: Divider()),
          children[i],
        ],
      ],
    ),
  );
}

/// Asks before deleting, says plainly what goes and what the agency keeps.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.appRead;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('account_deleted');
    try {
      await app.deleteAccount();
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.key);
    } catch (_) {
      if (mounted) setState(() => _error = 'err_generic');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('delete_account_title'),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.onyx),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('delete_account_body'),
            style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('delete_account_kept'),
            style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.muted),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.ink),
            onPressed: () => openLegal(context, 'delete-account'),
            child: Text(
              context.tr('delete_account_more'),
              style: const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              context.tr(_error!),
              style: const TextStyle(color: AppColors.onyx, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          PillButton(label: context.tr('delete_account_confirm'), loading: _busy, onPressed: _delete),
          const SizedBox(height: 10),
          PillButton(
            label: context.tr('cancel'),
            secondary: true,
            onPressed: _busy ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.onyx)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.ink,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.trailing, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: danger ? AppColors.white : AppColors.ink,
                shape: BoxShape.circle,
                border: danger ? Border.all(color: AppColors.line) : null,
              ),
              child: Icon(icon, color: danger ? AppColors.ink : AppColors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.onyx),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
            if (!danger) const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 42, onTap: () => Navigator.pop(context)),
        ),
      ),
      leadingWidth: 66,
      title: Text(title),
    ),
    body: child,
  );
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.app.savedProperties;
    return _SubPage(
      title: context.tr('saved_homes'),
      child: saved.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: context.tr('no_saved'),
              body: context.tr('no_saved_sub'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) => FeaturedPropertyCard(
                property: saved[i],
                height: 300,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: saved[i]))),
              ),
            ),
    );
  }
}

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final visits = context.app.upcomingVisits;
    return _SubPage(
      title: context.tr('my_visits'),
      child: visits.isEmpty
          ? EmptyState(icon: Icons.event_busy_outlined, title: context.tr('no_visits'), body: '')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: visits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = visits[i];
                return SurfaceCard(
                  padding: const EdgeInsets.all(10),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: v.property))),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: AppImage(v.property.cover, width: 70, height: 70, fit: BoxFit.cover, cacheWidth: 220),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.property.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${context.dayLabel(v.at)} · ${context.time(v.at)}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(v.property.agent.name, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
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
