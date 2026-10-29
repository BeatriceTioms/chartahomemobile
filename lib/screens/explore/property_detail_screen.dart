import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../utils/links.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/property_cards.dart';
import '../../widgets/property_map.dart';
import 'rent_application_screen.dart';
import 'book_stay_screen.dart';
import 'map_screen.dart';

const amenityIcons = <String, IconData>{
  'wifi': Icons.wifi_rounded,
  'parking': Icons.local_parking_rounded,
  'security': Icons.shield_outlined,
  'generator': Icons.bolt_rounded,
  'water': Icons.water_drop_outlined,
  'ac': Icons.ac_unit_rounded,
  'gym': Icons.fitness_center_rounded,
  'pool': Icons.pool_rounded,
  'elevator': Icons.elevator_outlined,
  'garden': Icons.yard_outlined,
};

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.property});
  final Property property;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _photo = 0;
  bool _expanded = false;

  /// Long-term rental or short stay; only switchable when the home offers
  /// short stays.
  bool _short = false;
  final _scroll = ScrollController();
  bool _pastPhoto = false;

  @override
  void initState() {
    super.initState();
    // Once the photo has scrolled away, give the status bar a white backdrop.
    _scroll.addListener(() {
      final past = _scroll.offset > 380;
      if (past != _pastPhoto) setState(() => _pastPhoto = past);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Property get p => widget.property;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // A Column rather than slivers so the rounded sheet paints over
          // the bottom of the photo.
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                _gallery(top),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 140),
                    child: _body(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAction(icon: Icons.arrow_back_ios_new_rounded, glass: true, onTap: () => Navigator.pop(context)),
                const Spacer(),
                CircleAction(
                  icon: Icons.ios_share_rounded,
                  glass: true,
                  onTap: () => toast(context, 'charta.home/l/${p.id}', icon: Icons.link_rounded),
                ),
                const SizedBox(width: 10),
                FavoriteButton(property: p, size: 46),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _pastPhoto ? 1 : 0,
                child: const ColoredBox(color: AppColors.white),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar()),
        ],
      ),
    );
  }

  Widget _gallery(double top) {
    return SizedBox(
      height: 440 + top * 0.3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'photo-${p.id}',
            child: PageView.builder(
              itemCount: p.photos.length,
              onPageChanged: (i) => setState(() => _photo = i),
              itemBuilder: (_, i) => AppImage(p.photos[i], fit: BoxFit.cover, cacheWidth: 1200),
            ),
          ),
          Positioned(
            bottom: 46,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassChip(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < p.photos.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _photo ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: i == _photo ? 1 : 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPill(label: context.kindLabel(p.kind), color: AppColors.ink, background: AppColors.white, dot: false),
            const SizedBox(width: 8),
            if (p.isVerified)
              StatusPill(label: context.tr('verified'), color: AppColors.ink, background: AppColors.white),
            const Spacer(),
            const Icon(Icons.star_rounded, color: AppColors.ink, size: 20),
            const SizedBox(width: 3),
            Text('${p.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '  (${context.tr('reviews', {'n': p.reviews})})',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(p.title, style: AppTheme.serif(size: 28)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 17, color: AppColors.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text('${p.building} · ${p.address}', style: const TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            _Spec(icon: Icons.bed_outlined, label: context.beds(p.rooms)),
            const SizedBox(width: 10),
            _Spec(icon: Icons.bathtub_outlined, label: context.baths(p.bathrooms)),
            const SizedBox(width: 10),
            _Spec(icon: Icons.square_foot_rounded, label: context.tr('sqm', {'n': p.sqm})),
            const SizedBox(width: 10),
            _Spec(icon: Icons.layers_outlined, label: '${context.tr('floor')} ${p.floor}'),
          ],
        ),
        const SizedBox(height: 28),
        if (p.shortStay) ...[
          _ModeSwitch(short: _short, onChanged: (v) => setState(() => _short = v)),
          const SizedBox(height: 28),
        ],
        Text(context.tr('description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Text(
            p.description,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.55),
          ),
        ),
        if (!_expanded)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.tr('read_more'),
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ),
        const SizedBox(height: 28),
        Text(
          context.tr(_short ? 'stay_terms' : 'lease_terms'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _short ? _StayTerms(key: const ValueKey('stay'), property: p) : _LeaseTerms(property: p),
        ),
        const SizedBox(height: 28),
        Text(context.tr('amenities'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final a in p.amenities) InfoTag(icon: amenityIcons[a], label: context.tr(a))],
        ),
        const SizedBox(height: 28),
        // Only when the agency has placed the building on the map.
        if (p.lat != 0 || p.lng != 0) ...[
          Text(context.tr('location'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${p.building} · ${p.address}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          PropertyMapPreview(
            property: p,
            onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapScreen(property: p))),
          ),
        ],
        const SizedBox(height: 28),
        Text(context.tr('your_agent'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Avatar(image: p.agent.photo, name: p.agent.name, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.agent.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.ink),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${p.agent.rating} · ${p.agency}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAction(
                icon: Icons.call_rounded,
                size: 44,
                color: AppColors.white,
                background: AppColors.ink,
                tooltip: context.tr('call'),
                onTap: () => callNumber(context, p.agent.phone),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Floating oval like the bottom menu: the price on the left, the blue
  /// "Rent this home" button on the right. No solid bar behind it.
  Widget _bottomBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: LiquidGlass(
          radius: 100,
          padding: const EdgeInsets.fromLTRB(22, 6, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('price'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: context.money(_short ? p.nightlyRate! : p.rent),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                            ),
                            TextSpan(
                              text: context.tr(_short ? 'per_night' : 'per_month'),
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.brand,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _short ? BookStayScreen(property: p) : RentApplicationScreen(property: p),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    child: Text(
                      _short
                          ? context.tr('book_stay')
                          : !p.availabilityKnown
                          ? context.tr('submit_application')
                          : p.availableNow
                          ? context.tr('book_rent')
                          : context.tr('book_from', {'date': context.dateShort(p.availableFrom)}),
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
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

/// Two-way switch between renting monthly and booking a short stay.
/// The chosen side is brand blue with white text.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.short, required this.onChanged});
  final bool short;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget side(bool value, IconData icon, String label) {
      final on = short == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46,
            decoration: BoxDecoration(
              color: on ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: on ? AppColors.white : AppColors.ink),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: on ? AppColors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          side(false, Icons.home_outlined, context.tr('long_term')),
          side(true, Icons.nights_stay_outlined, context.tr('short_stay')),
        ],
      ),
    );
  }
}

/// Short stay: nightly price, what 1, 3 and 7 nights cost, and the
/// check-in / check-out times.
class _StayTerms extends StatelessWidget {
  const _StayTerms({super.key, required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final rate = property.nightlyRate!;
    final next = context.app.nextFreeCheckIn(property);
    final today = DateTime.now();
    final nextLabel = next == null
        ? context.tr('fully_booked')
        : (next.year == today.year && next.month == today.month && next.day == today.day)
        ? context.tr('tonight')
        : context.weekdayDate(next);
    return SurfaceCard(
      border: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _Term(
            icon: Icons.nights_stay_outlined,
            label: context.tr('nightly_rate'),
            value: context.money(rate),
            hint: context.tr('no_deposit'),
          ),
          const Divider(),
          _Term(
            icon: Icons.event_available_outlined,
            label: context.tr('next_free_night'),
            value: nextLabel,
            hint: context.tr('from_agency_calendar'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('agency_packages'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                const SizedBox(height: 10),
                // The agency's own packages (stay_rates on the web), any length
                // in between is priced from the longest package that fits.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in property.packageNights)
                      Container(
                        width: 96,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr(n == 1 ? 'night_one' : 'nights', {'n': n}),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.money(property.stayRates[n]!),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _Term(icon: Icons.login_rounded, label: context.tr('check_in'), value: context.tr('check_in_time')),
          const Divider(),
          _Term(icon: Icons.logout_rounded, label: context.tr('check_out'), value: context.tr('check_out_time')),
        ],
      ),
    );
  }
}

/// One line per term: monthly rent, security deposit, availability.
class _LeaseTerms extends StatelessWidget {
  const _LeaseTerms({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final depositMonths = p.rent == 0 ? 0 : (p.deposit / p.rent).round();
    return SurfaceCard(
      border: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _Term(icon: Icons.payments_outlined, label: context.tr('monthly_rent'), value: context.money(p.rent)),
          const Divider(),
          _Term(
            icon: Icons.verified_user_outlined,
            label: context.tr('deposit'),
            value: context.money(p.deposit),
            hint: depositMonths > 0 ? context.tr('months_of_rent', {'n': depositMonths}) : null,
          ),
          const Divider(),
          _Term(
            icon: Icons.event_available_outlined,
            label: context.tr('available_from'),
            value: !p.availabilityKnown
                ? context.tr('occupied_unknown')
                : p.availableNow
                ? context.tr('available_now')
                : context.date(p.availableFrom),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term({required this.icon, required this.label, required this.value, this.hint});
  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: AppColors.white, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              if (hint != null) Text(hint!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
      ],
    ),
  );
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: LiquidGlass(
      radius: AppRadius.sm + 2,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: AppColors.ink, size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ],
      ),
    ),
  );
}
