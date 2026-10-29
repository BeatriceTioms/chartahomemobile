import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// When the home can be moved into: now, from a date (the current lease's
/// end), or not yet known (a lease with no end date).
String availabilityText(BuildContext context, Property p) {
  if (!p.availabilityKnown) return context.tr('occupied_unknown');
  if (p.availableNow) return context.tr('free_now');
  return context.tr('free_on', {'date': context.dateShort(p.availableFrom)});
}

/// Frosted chip that sits on top of photos (price, match score, tags).
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.light = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool light;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: light ? AppColors.white.withValues(alpha: 0.85) : AppColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.white.withValues(alpha: light ? 0.9 : 0.28)),
        ),
        child: child,
      ),
    ),
  );
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.property, this.size = 38});
  final Property property;
  final double size;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final saved = app.isSaved(property);
    return CircleAction(
      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: saved ? AppColors.ink : AppColors.onyx,
      size: size,
      glass: true,
      tooltip: 'Save',
      onTap: () {
        app.toggleSaved(property);
        toast(
          context,
          context.tr(saved ? 'removed_toast' : 'saved_toast'),
          icon: saved ? Icons.heart_broken_rounded : Icons.favorite_rounded,
        );
      },
    );
  }
}

/// Large photo card with the details overlaid on a gradient (reference 1 & 6).
class FeaturedPropertyCard extends StatelessWidget {
  const FeaturedPropertyCard({super.key, required this.property, required this.onTap, this.height = 360});
  final Property property;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'photo-${p.id}',
        child: Container(
          height: height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppColors.liftShadow),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(p.cover, fit: BoxFit.cover, cacheWidth: 900),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1],
                      colors: [Colors.transparent, Color(0xE6001A2C)],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      if (p.matchScore != null)
                        GlassChip(
                          light: true,
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.ink),
                              const SizedBox(width: 5),
                              Text(
                                context.tr('match', {'n': p.matchScore!}),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (p.isNew)
                        GlassChip(
                          light: true,
                          child: Text(
                            context.tr('new'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      if (!p.availableNow) ...[
                        const SizedBox(width: 6),
                        GlassChip(
                          light: true,
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 14, color: AppColors.ink),
                              const SizedBox(width: 5),
                              Text(
                                availabilityText(context, p),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (p.shortStay) ...[
                        const SizedBox(width: 6),
                        GlassChip(
                          light: true,
                          child: Row(
                            children: [
                              const Icon(Icons.nights_stay_outlined, size: 14, color: AppColors.ink),
                              const SizedBox(width: 5),
                              Text(
                                context.tr('short_stay'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(top: 14, right: 14, child: FavoriteButton(property: p, size: 42)),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 15, color: AppColors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 13.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: context.money(p.rent),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: context.tr('per_month'),
                                    style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.75)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InfoTag(dark: true, compact: true, icon: Icons.bed_outlined, label: context.beds(p.rooms)),
                            InfoTag(
                              dark: true,
                              compact: true,
                              icon: Icons.bathtub_outlined,
                              label: context.baths(p.bathrooms),
                            ),
                            InfoTag(
                              dark: true,
                              compact: true,
                              icon: Icons.square_foot_rounded,
                              label: context.tr('sqm', {'n': p.sqm}),
                            ),
                          ],
                        ),
                      ],
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

/// Tall grid card like the Paris travel reference (reference 1).
class TilePropertyCard extends StatelessWidget {
  const TilePropertyCard({super.key, required this.property, required this.onTap, this.width = 200});
  final Property property;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(p.cover, fit: BoxFit.cover, cacheWidth: 600),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1],
                    colors: [Colors.transparent, Color(0xD9001A2C)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: GlassChip(
                  child: Text(
                    context.money(p.rent, compact: true),
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ),
              Positioned(top: 10, right: 10, child: FavoriteButton(property: p, size: 34)),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GlassChip(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: AppColors.white),
                              const SizedBox(width: 3),
                              Text(
                                '${p.rating}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: GlassChip(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Text(
                              context.beds(p.rooms),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal list card with thumbnail (reference 7), used for lists and
/// search results.
class ListPropertyCard extends StatelessWidget {
  const ListPropertyCard({super.key, required this.property, required this.onTap});
  final Property property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final saved = context.app.isSaved(p);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 116,
              height: 124,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(p.cover, fit: BoxFit.cover, cacheWidth: 360),
                  if (p.matchScore != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GlassChip(
                        light: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '${p.matchScore}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.money(p.rent),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.appRead.toggleSaved(p),
                      child: Icon(
                        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 22,
                        color: saved ? AppColors.ink : AppColors.faint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        p.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${context.beds(p.rooms)}  ·  ${context.baths(p.bathrooms)}  ·  ${context.tr('sqm', {'n': p.sqm})}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      p.availableNow ? Icons.check_circle_outline_rounded : Icons.event_outlined,
                      size: 14,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        availabilityText(context, p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (p.shortStay) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.nights_stay_outlined, size: 14, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          context.tr('from_per_night', {'amount': context.money(p.nightlyRate!)}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
