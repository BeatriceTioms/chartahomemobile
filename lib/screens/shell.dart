import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'explore/explore_screen.dart';
import 'home/my_home_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'payments/payments_screen.dart';

/// Lets any screen switch tabs (e.g. "Pay rent" on My home → Payments).
class ShellController extends InheritedWidget {
  const ShellController({super.key, required this.goTo, required super.child});
  final void Function(int index) goTo;

  static ShellController of(BuildContext context) => context.getInheritedWidgetOfExactType<ShellController>()!;

  @override
  bool updateShouldNotify(ShellController oldWidget) => false;
}

class Tabs {
  static const explore = 0;
  static const home = 1;
  static const pay = 2;
  static const repairs = 3;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Everyone lands on Explore after signing up or in.
  int _index = Tabs.explore;

  static const _pages = [ExploreScreen(), MyHomeScreen(), PaymentsScreen(), MaintenanceScreen()];

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return ShellController(
      goTo: _go,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // Each tab states its status bar style; without this, leaving the
            // blue Payments header kept white icons on the white tabs.
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: _index == Tabs.pay ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              child: IndexedStack(index: _index, children: _pages),
            ),
            // Keeps scrolled content from running under the clock.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: ColoredBox(
                // Payments has a blue header running up under the clock.
                color: _index == Tabs.pay ? AppColors.brandHeaderTop : AppColors.canvas.withValues(alpha: 0.94),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _FloatingNav(index: _index, onTap: _go),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating glass pill with the active tab expanded into a labelled glass
/// capsule (references 3 and 6). The profile lives in the top bar.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final items = [
      _NavItem(Icons.explore_outlined, Icons.explore_rounded, context.tr('nav_explore')),
      _NavItem(Icons.home_outlined, Icons.home_rounded, context.tr('nav_home')),
      _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, context.tr('nav_pay')),
      _NavItem(Icons.handyman_outlined, Icons.handyman_rounded, context.tr('nav_repairs')),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: _Glass(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavButton(
                    item: items[i],
                    active: i == index,
                    onTap: () => onTap(i),
                    badge: i == Tabs.pay && app.balanceDue > 0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), boxShadow: AppColors.liftShadow),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.white),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap, this.badge = false});
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: active ? 5 : 3,
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 52,
            // The active tab is a small liquid-glass lens inside the bar.
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.white.withValues(alpha: 0.95), AppColors.cloud.withValues(alpha: 0.7)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: active ? AppColors.white : Colors.transparent, width: 1.2),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.onyx.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      active ? item.activeIcon : item.icon,
                      size: 23,
                      color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.6),
                    ),
                    if (badge)
                      Positioned(
                        right: -2,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                if (active)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
