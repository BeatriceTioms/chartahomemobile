import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/property_cards.dart';
import '../../widgets/top_bar.dart';
import 'filters_screen.dart';
import 'property_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  PropertyKind? _kind;
  ExploreFilters _filters = const ExploreFilters();
  final _pager = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _search.dispose();
    _pager.dispose();
    super.dispose();
  }

  bool get _searching => _search.text.trim().isNotEmpty || _kind != null || _filters.active;

  List<Property> _apply(List<Property> all, {ExploreFilters? filters}) {
    final q = _search.text.trim().toLowerCase();
    final f = filters ?? _filters.withKind(_kind);
    return all.where((p) {
      if (!f.matches(p)) return false;
      if (q.isNotEmpty && !'${p.title} ${p.building} ${p.neighborhood} ${p.city}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _open(Property p) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<ExploreFilters>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FiltersScreen(
          initial: _filters.withKind(_kind),
          count: (f) => _apply(context.appRead.properties, filters: f).length,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _filters = result;
        _kind = result.kind;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final results = _apply(app.properties);
    final scored = app.properties.where((p) => p.matchScore != null).toList()
      ..sort((a, b) => b.matchScore!.compareTo(a.matchScore!));
    // Live listings carry no match score yet: feature the first few instead.
    final matches = scored.isNotEmpty ? scored : app.properties.take(5).toList();
    final recent = app.properties.where((p) => p.matchScore == null || p.isNew).toList();

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => context.appRead.loadListings().catchError((_) {}),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TopBar(),
                    const SizedBox(height: 22),
                    Text(
                      context.tr('hello', {'name': app.user.firstName}),
                      style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(context.tr('explore_title'), maxLines: 1, style: AppTheme.serif(size: 30)),
                    ),
                    const SizedBox(height: 20),
                    _SearchBar(
                      controller: _search,
                      filtersActive: _filters.active,
                      onChanged: () => setState(() {}),
                      onFilters: _openFilters,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _kindChip(null, Icons.grid_view_rounded, context.tr('all')),
                  _kindChip(PropertyKind.apartment, Icons.apartment_rounded, context.tr('apartment')),
                  _kindChip(PropertyKind.studio, Icons.single_bed_rounded, context.tr('studio')),
                  _kindChip(PropertyKind.duplex, Icons.stairs_rounded, context.tr('duplex')),
                  _kindChip(PropertyKind.villa, Icons.villa_rounded, context.tr('villa')),
                ],
              ),
            ),
          ),
          if (_searching) ..._resultSlivers(results) else ..._discoverSlivers(matches, recent),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _kindChip(PropertyKind? kind, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChipPill(
      label: label,
      icon: icon,
      dense: true,
      selected: _kind == kind,
      onTap: () => setState(() => _kind = kind),
    ),
  );

  List<Widget> _discoverSlivers(List<Property> matches, List<Property> recent) => [
    if (context.app.properties.isEmpty)
      SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.apartment_rounded,
          title: context.tr('no_listings'),
          body: context.tr('no_listings_sub'),
        ),
      )
    else ...[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(title: context.tr('top_matches'), subtitle: context.tr('top_matches_sub')),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pager,
            padEnds: false,
            itemCount: matches.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6, bottom: 20),
              child: FeaturedPropertyCard(property: matches[i], onTap: () => _open(matches[i])),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: context.tr('near_you'),
            action: context.tr('see_all'),
            onAction: () => setState(() => _kind = PropertyKind.apartment),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => TilePropertyCard(property: recent[i], onTap: () => _open(recent[i]), width: 190),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: context.tr(context.app.properties.length == 1 ? 'results_one' : 'results', {
              'n': context.app.properties.length,
            }),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: context.app.properties.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final p = context.app.properties[i];
            return ListPropertyCard(property: p, onTap: () => _open(p));
          },
        ),
      ),
    ],
  ];

  List<Widget> _resultSlivers(List<Property> results) => [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      sliver: SliverToBoxAdapter(
        child: SectionHeader(
          title: context.tr(results.length == 1 ? 'results_one' : 'results', {'n': results.length}),
          action: context.tr('reset'),
          onAction: () => setState(() {
            _search.clear();
            _kind = null;
            _filters = const ExploreFilters();
          }),
        ),
      ),
    ),
    if (results.isEmpty)
      SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: context.tr('no_results'),
          body: context.tr('no_results_sub'),
        ),
      )
    else
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, i) =>
              FeaturedPropertyCard(property: results[i], height: 300, onTap: () => _open(results[i])),
        ),
      ),
  ];
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilters,
    required this.filtersActive,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onFilters;
  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                const Icon(Icons.search_rounded, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: context.tr('search_hint'),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                    onPressed: () {
                      controller.clear();
                      onChanged();
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        CircleAction(
          icon: Icons.tune_rounded,
          size: 56,
          tooltip: context.tr('filters'),
          badge: filtersActive,
          color: AppColors.white,
          background: AppColors.brand,
          onTap: onFilters,
        ),
      ],
    );
  }
}
