import 'package:flutter/material.dart';

import '../../services/notifications.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Shown once, after onboarding: explains what we notify about, then asks
/// the system for permission. Asking from a screen like this, rather than at
/// launch, is what makes people say yes.
class NotificationsPermissionScreen extends StatefulWidget {
  const NotificationsPermissionScreen({super.key});

  @override
  State<NotificationsPermissionScreen> createState() => _NotificationsPermissionScreenState();
}

class _NotificationsPermissionScreenState extends State<NotificationsPermissionScreen> {
  bool _busy = false;
  bool _news = true;

  Future<void> _allow() async {
    setState(() => _busy = true);
    var granted = false;
    try {
      granted = await NotificationService.instance.requestPermission();
    } catch (_) {
      // Not available (tests, desktop): carry on.
    }
    if (!mounted) return;
    final app = context.appRead;
    app.setNewsEnabled(_news);
    app.setNotificationsEnabled(granted);
    app.markNotificationsAsked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned(top: -120, right: -100, child: _soft(320)),
          Positioned(bottom: 120, left: -140, child: _soft(260)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : context.app.markNotificationsAsked,
                      child: Text(
                        context.tr('not_now'),
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const _Preview(),
                  const Spacer(),
                  Text(context.tr('notif_title'), textAlign: TextAlign.center, style: AppTheme.serif(size: 30)),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('notif_body'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 15.5, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  // Promotional notices need a clear yes (App Store 4.5.4),
                  // so they have their own switch, changeable in Profile.
                  GestureDetector(
                    onTap: () => setState(() => _news = !_news),
                    child: Row(
                      children: [
                        Checkbox.adaptive(
                          value: _news,
                          activeColor: AppColors.ink,
                          onChanged: (v) => setState(() => _news = v ?? false),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr('notif_news'),
                            style: const TextStyle(color: AppColors.onyx, fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    color: AppColors.brand,
                    icon: Icons.notifications_active_outlined,
                    label: context.tr('notif_allow'),
                    loading: _busy,
                    onPressed: _allow,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('notif_later'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.faint, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _soft(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [AppColors.soft200, Color(0x00FFFFFF)]),
    ),
  );
}

/// A bell in a soft halo with three example notifications fanned around it.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.account_balance_wallet_outlined, context.tr('notif_ex_rent'), context.tr('notif_ex_rent_sub')),
      (Icons.handyman_outlined, context.tr('notif_ex_repair'), context.tr('notif_ex_repair_sub')),
      (Icons.nights_stay_outlined, context.tr('notif_ex_stay'), context.tr('notif_ex_stay_sub')),
    ];
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14)),
            ],
          ),
          child: const Icon(Icons.notifications_rounded, color: AppColors.white, size: 52),
        ),
        const SizedBox(height: 28),
        for (var i = 0; i < cards.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + i * 180),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, (1 - v) * 20), child: child),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: 10, left: i.isOdd ? 24 : 0, right: i.isOdd ? 0 : 24),
              child: LiquidGlass(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                      child: Icon(cards[i].$1, color: AppColors.white, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cards[i].$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(cards[i].$3, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
