import 'package:flutter/material.dart';

import '../screens/profile/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'logo.dart';

/// Header shared by every tab: the Charta Home wordmark on the left, then
/// notifications and the resident's photo, which opens the profile.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final goTo = ShellController.of(context).goTo;
    return Row(
      children: [
        const Wordmark(size: 19),
        const Spacer(),
        CircleAction(
          icon: Icons.notifications_none_rounded,
          size: 44,
          badge: app.unreadCount > 0,
          tooltip: context.tr('notifications'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: context.tr('profile'),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(onOpenTab: goTo))),
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: AppColors.softShadow,
              ),
              child: ClipOval(child: AppImage(app.user.photo, fit: BoxFit.cover, cacheWidth: 150)),
            ),
          ),
        ),
      ],
    );
  }
}
