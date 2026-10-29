import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A round white button with a soft shadow, used for back, favourite, share
/// and similar icon actions (as in the reference designs).
class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.color = AppColors.onyx,
    this.background = AppColors.white,
    this.glass = false,
    this.badge = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final Color background;
  final bool glass;
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: glass ? AppColors.white.withValues(alpha: 0.72) : background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.44, color: color),
        ),
      ),
    );
    if (glass) {
      button = ClipOval(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: button),
      );
    }
    return Semantics(
      button: true,
      label: tooltip,
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: glass ? null : AppColors.softShadow),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            if (badge)
              Positioned(
                right: size * 0.22,
                top: size * 0.22,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: background, width: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width pill button. Primary is black with white text; secondary is a
/// grey pill, as in the "Schedule / Book now" pair of the references.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.loading = false,
    this.height = 58,
    this.expand = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool loading;
  final double height;
  final bool expand;

  /// Fill for the primary style; defaults to black.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final bg = secondary ? AppColors.white : (color ?? AppColors.ink);
    final fg = secondary ? AppColors.ink : AppColors.white;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.4,
      child: SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          shape: StadiumBorder(side: secondary ? const BorderSide(color: AppColors.line) : BorderSide.none),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: loading
                    ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 10)],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable chip; brand azure with white text when selected, white otherwise.
class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 18, vertical: dense ? 9 : 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.brand : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: selected ? AppColors.white : AppColors.ink),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: dense ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.onyx,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded tag like "3 Beds" / "1200 sq ft" in the references.
class InfoTag extends StatelessWidget {
  const InfoTag({super.key, required this.label, this.icon, this.dark = false, this.compact = false});
  final String label;
  final IconData? icon;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.white : AppColors.onyx;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.16) : AppColors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: dark ? AppColors.white.withValues(alpha: 0.22) : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 15, color: fg.withValues(alpha: 0.8)),
            SizedBox(width: compact ? 5 : 6),
          ],
          Text(
            label,
            style: TextStyle(fontSize: compact ? 12 : 12.5, fontWeight: FontWeight.w500, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Coloured status pill.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, required this.background, this.dot = true});
  final String label;
  final Color color;
  final Color background;
  final bool dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
      // White pills sit on white cards, so they need an edge.
      border: background == AppColors.white ? Border.all(color: AppColors.line) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// White rounded card with the brand's soft shadow.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.radius = AppRadius.lg,
    this.color = AppColors.white,
    this.border = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: border ? null : AppColors.softShadow,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border ? const BorderSide(color: AppColors.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action, this.onAction});
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                action!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// Friendly empty state with a soft icon badge.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            PillButton(label: action!, onPressed: onAction, expand: false, height: 50),
          ],
        ],
      ),
    );
  }
}

/// Round portrait, or the person's initials when there is no photo.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.image, this.name = '', this.size = 44, this.ring = false});
  final String? image;
  final String name;
  final double size;
  final bool ring;

  String get _initials =>
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(ring ? 2.5 : 0),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white,
      boxShadow: ring ? AppColors.softShadow : null,
    ),
    child: ClipOval(
      child: image != null && image!.isNotEmpty
          ? AppImage(image!, cacheWidth: (size * 3).round())
          : ColoredBox(
              color: AppColors.ink,
              child: Center(
                child: Text(
                  _initials,
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36),
                ),
              ),
            ),
    ),
  );
}

/// Bottom sheet helper so every sheet shares the same shape and safe area.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder, bool expand = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    builder: (ctx) => expand ? FractionallySizedBox(heightFactor: 0.94, child: builder(ctx)) : builder(ctx),
  );
}

void toast(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Label/value line used in summaries and receipts.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.onyx : AppColors.muted,
            fontSize: 14.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: bold ? 16 : 14.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

/// Big success confirmation used at the end of every flow.
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.title,
    required this.body,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
    this.extra,
  });

  final String title;
  final String body;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
                boxShadow: AppColors.softShadow,
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: AppTheme.serif(size: 26)),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
          ),
          if (extra != null) ...[const SizedBox(height: 20), extra!],
          const SizedBox(height: 28),
          PillButton(label: primary, onPressed: onPrimary),
          if (secondary != null) ...[
            const SizedBox(height: 10),
            PillButton(label: secondary!, onPressed: onSecondary, secondary: true),
          ],
        ],
      ),
    );
  }
}

/// A light "liquid glass" surface: a softly blurred, mostly white pane with
/// a bright top edge. Kept subtle so it reads as frosted, not see-through.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({super.key, required this.child, this.radius = AppRadius.md, this.padding = EdgeInsets.zero});
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(color: AppColors.onyx.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.white.withValues(alpha: 0.72), AppColors.cloud.withValues(alpha: 0.62)],
              ),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shows a bundled asset (demo data) or a signed URL from the server, with a
/// calm placeholder while loading or when there is no picture.
class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.alignment = Alignment.center,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final Alignment alignment;

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.soft100,
    alignment: Alignment.center,
    child: const Icon(Icons.apartment_rounded, color: AppColors.soft500),
  );

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return _placeholder();
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: fit, width: width, height: height, cacheWidth: cacheWidth, alignment: alignment);
    }
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      alignment: alignment,
      loadingBuilder: (_, child, progress) => progress == null ? child : _placeholder(),
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }
}
