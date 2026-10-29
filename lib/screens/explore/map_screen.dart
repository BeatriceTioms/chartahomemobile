import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/property_map.dart';
import '../../widgets/property_cards.dart';
import 'property_detail_screen.dart';

/// Full-screen map (reference design): the listing and its neighbours as
/// photo pins on a grey map, with a card for the selected home at the bottom.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.property});
  final Property property;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  late Property _selected = widget.property;

  List<Property> get _nearby => context.app.properties.where((p) => p.city == widget.property.city).toList();

  void _select(Property p) {
    setState(() => _selected = p);
    _map.move(LatLng(p.lat, p.lng), _map.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final p = _selected;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(initialCenter: LatLng(p.lat, p.lng), initialZoom: 14.5),
            children: [
              const GreyTiles(),
              MarkerLayer(
                markers: [
                  for (final n in _nearby)
                    Marker(
                      point: LatLng(n.lat, n.lng),
                      width: 230,
                      height: 70,
                      alignment: const Alignment(0.75, -0.6),
                      child: GestureDetector(
                        onTap: () => _select(n),
                        child: PropertyPin(property: n, active: n.id == p.id, compact: n.id != p.id),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAction(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Text(
                    context.tr('map'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                CircleAction(
                  icon: Icons.my_location_rounded,
                  tooltip: context.tr('recenter'),
                  onTap: () => _map.move(LatLng(p.lat, p.lng), 15),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: _SelectedCard(
              property: p,
              onOpen: p.id == widget.property.id
                  ? () => Navigator.pop(context)
                  : () => Navigator.of(
                      context,
                    ).pushReplacement(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({required this.property, required this.onOpen});
  final Property property;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppColors.liftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AppImage(p.cover, width: 86, height: 86, fit: BoxFit.cover, cacheWidth: 260),
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
                            p.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ),
                        FavoriteButton(property: p, size: 36),
                      ],
                    ),
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.beds(p.rooms)}  ·  ${context.baths(p.bathrooms)}  ·  ${context.tr('sqm', {'n': p.sqm})}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.money(p.rent),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      TextSpan(
                        text: context.tr('per_month'),
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, size: 18, color: AppColors.ink),
              const SizedBox(width: 3),
              Text('${p.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              CircleAction(
                icon: Icons.arrow_forward_rounded,
                size: 48,
                color: AppColors.white,
                background: AppColors.brand,
                onTap: onOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
