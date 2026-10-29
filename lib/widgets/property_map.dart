import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// OpenStreetMap tiles drawn in greyscale, so the map stays a quiet white and
/// grey backdrop (reference design) and never adds colours to the app.
class GreyTiles extends StatelessWidget {
  const GreyTiles({super.key});

  static const _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 18, //
    0.2126, 0.7152, 0.0722, 0, 18,
    0.2126, 0.7152, 0.0722, 0, 18,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: _greyscale,
    child: TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.chartahome.app',
      maxNativeZoom: 19,
    ),
  );
}

/// Map marker: the building photo in a round frame with a label bubble
/// (name, rating, price) beside it, as in the reference.
class PropertyPin extends StatelessWidget {
  const PropertyPin({super.key, required this.property, this.active = false, this.compact = false});
  final Property property;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: active ? AppColors.brand : AppColors.white, width: 1.5),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: AppImage(
                  p.cover,
                  width: compact ? 30 : 40,
                  height: compact ? 30 : 40,
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 120 : 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                    if (!compact)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.ink),
                          const SizedBox(width: 2),
                          Text('${p.rating}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              context.money(p.rent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
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
        // Small dot marking the exact spot under the photo.
        Padding(
          padding: EdgeInsets.only(left: compact ? 15 : 20, top: 4),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: active ? AppColors.brand : AppColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Non-interactive map preview for the listing page.
class PropertyMapPreview extends StatelessWidget {
  const PropertyMapPreview({super.key, required this.property, required this.onOpen});
  final Property property;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final at = LatLng(property.lat, property.lng);
    return GestureDetector(
      onTap: onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 190,
          child: Stack(
            children: [
              IgnorePointer(
                child: FlutterMap(
                  // Centre a little east of the building so the label, which sits to
                  // the right of the dot, stays fully inside the preview.
                  options: MapOptions(initialCenter: LatLng(at.latitude, at.longitude + 0.007), initialZoom: 14.2),
                  children: [
                    const GreyTiles(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: at,
                          width: 230,
                          height: 70,
                          alignment: const Alignment(0.75, -0.6),
                          child: PropertyPin(property: property, active: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_full_rounded, size: 15, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('open_map'),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
