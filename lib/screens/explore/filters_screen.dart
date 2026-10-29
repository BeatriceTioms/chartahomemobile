import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'property_detail_screen.dart' show amenityIcons;

/// Everything the Explore list can be narrowed by.
class ExploreFilters {
  const ExploreFilters({
    this.kind,
    this.minRent,
    this.maxRent,
    this.minRooms = 0,
    this.city,
    this.amenities = const {},
    this.shortStayOnly = false,
  });

  final PropertyKind? kind;
  final int? minRent;
  final int? maxRent;
  final int minRooms;
  final String? city;
  final Set<String> amenities;

  /// Only homes that can also be booked for 1, 3 or 7 nights.
  final bool shortStayOnly;

  /// True when anything beyond the category is set (the category has its own
  /// chips on Explore).
  bool get active =>
      minRent != null || maxRent != null || minRooms > 0 || city != null || amenities.isNotEmpty || shortStayOnly;

  bool matches(Property p) {
    if (kind != null && p.kind != kind) return false;
    if (minRent != null && p.rent < minRent!) return false;
    if (maxRent != null && p.rent > maxRent!) return false;
    if (p.rooms < minRooms) return false;
    if (city != null && p.city != city) return false;
    if (!amenities.every(p.amenities.contains)) return false;
    if (shortStayOnly && !p.shortStay) return false;
    return true;
  }

  ExploreFilters withKind(PropertyKind? k) => ExploreFilters(
    kind: k,
    minRent: minRent,
    maxRent: maxRent,
    minRooms: minRooms,
    city: city,
    amenities: amenities,
    shortStayOnly: shortStayOnly,
  );
}

/// Full-page filters (reference design): category chips, a two-handle price
/// range with From / To boxes, bedrooms, city and a grid of amenities.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.initial, required this.count});
  final ExploreFilters initial;
  final int Function(ExploreFilters) count;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  static const _floor = 50000.0;
  static const _ceiling = 800000.0;

  late PropertyKind? _kind = widget.initial.kind;
  late RangeValues _range = RangeValues(
    (widget.initial.minRent ?? _floor).toDouble(),
    (widget.initial.maxRent ?? _ceiling).toDouble(),
  );
  late int _rooms = widget.initial.minRooms;
  late String? _city = widget.initial.city;
  late final Set<String> _amenities = {...widget.initial.amenities};
  late bool _shortOnly = widget.initial.shortStayOnly;

  ExploreFilters get _value => ExploreFilters(
    kind: _kind,
    minRent: _range.start <= _floor ? null : _range.start.round(),
    maxRent: _range.end >= _ceiling ? null : _range.end.round(),
    minRooms: _rooms,
    city: _city,
    amenities: {..._amenities},
    shortStayOnly: _shortOnly,
  );

  void _reset() => setState(() {
    _kind = null;
    _range = const RangeValues(_floor, _ceiling);
    _rooms = 0;
    _city = null;
    _amenities.clear();
    _shortOnly = false;
  });

  @override
  Widget build(BuildContext context) {
    final kinds = <(PropertyKind?, String)>[
      (null, context.tr('all')),
      (PropertyKind.apartment, context.tr('apartment')),
      (PropertyKind.studio, context.tr('studio')),
      (PropertyKind.duplex, context.tr('duplex')),
      (PropertyKind.villa, context.tr('villa')),
      (PropertyKind.house, context.tr('house')),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 46, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 70,
        title: Text(context.tr('filters')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAction(icon: Icons.restart_alt_rounded, size: 46, tooltip: context.tr('reset'), onTap: _reset),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
            children: [
              _Label(context.tr('category')),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: kinds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChipPill(
                    label: kinds[i].$2,
                    selected: _kind == kinds[i].$1,
                    onTap: () => setState(() => _kind = kinds[i].$1),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _Label(context.tr('price_range')),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.brand,
                  inactiveTrackColor: AppColors.silver,
                  trackHeight: 4,
                  rangeThumbShape: const _RingThumb(),
                  rangeTickMarkShape: const RoundRangeSliderTickMarkShape(tickMarkRadius: 0),
                  overlayColor: AppColors.brand.withValues(alpha: 0.08),
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: RangeSlider(
                  values: _range,
                  min: _floor,
                  max: _ceiling,
                  divisions: 30,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _range = v);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Text(
                      context.money(_floor.round(), compact: true),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '${context.money(_ceiling.round(), compact: true)}+',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PriceBox(label: context.tr('from'), value: context.money(_range.start.round())),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PriceBox(
                      label: context.tr('to'),
                      value: _range.end >= _ceiling ? context.tr('any') : context.money(_range.end.round()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Label(context.tr('min_bedrooms')),
              Row(
                children: [
                  for (final n in [0, 1, 2, 3, 4]) ...[
                    if (n > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Toggle(
                        label: n == 0 ? context.tr('any') : '$n+',
                        selected: _rooms == n,
                        onTap: () => setState(() => _rooms = n),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              _Label(context.tr('stay_type')),
              Row(
                children: [
                  Expanded(
                    child: _Toggle(
                      label: context.tr('any'),
                      selected: !_shortOnly,
                      onTap: () => setState(() => _shortOnly = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Toggle(
                      label: context.tr('short_stays_only'),
                      icon: Icons.nights_stay_outlined,
                      selected: _shortOnly,
                      onTap: () => setState(() => _shortOnly = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Label(context.tr('city')),
              Row(
                children: [
                  for (final c in [null, 'Yaoundé', 'Douala']) ...[
                    if (c != null) const SizedBox(width: 8),
                    Expanded(
                      child: _Toggle(
                        label: c ?? context.tr('any'),
                        selected: _city == c,
                        onTap: () => setState(() => _city = c),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              _Label(context.tr('amenities')),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.3,
                children: [
                  for (final a in amenityIcons.keys)
                    _Toggle(
                      label: context.tr(a),
                      icon: amenityIcons[a],
                      selected: _amenities.contains(a),
                      onTap: () => setState(() => _amenities.contains(a) ? _amenities.remove(a) : _amenities.add(a)),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: PillButton(
              label: context.tr('show_homes', {'n': widget.count(_value)}),
              onPressed: () => Navigator.pop(context, _value),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}

/// White pill that turns brand blue with white text when on.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.brand : AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 7)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
        const Spacer(),
        Flexible(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ),
      ],
    ),
  );
}

/// White thumb with a blue ring, as in the reference.
class _RingThumb extends RangeSliderThumbShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    TextDirection textDirection = TextDirection.ltr,
    required SliderThemeData sliderTheme,
    Thumb thumb = Thumb.start,
    bool isPressed = false,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center + const Offset(0, 1.5), 11, Paint()..color = AppColors.onyx.withValues(alpha: 0.12));
    canvas.drawCircle(center, 11, Paint()..color = AppColors.white);
    canvas.drawCircle(
      center,
      9.5,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
