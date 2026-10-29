import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'maintenance_screen.dart';

/// Photos come from the device (file paths) or from the demo data (assets).
Widget ticketImage(String path, {BoxFit fit = BoxFit.cover}) => path.startsWith('assets/') || path.startsWith('http')
    ? AppImage(path, fit: fit, cacheWidth: 500)
    : Image.file(File(path), fit: fit, cacheWidth: 500);

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key, this.initialCategory});
  final TicketCategory? initialCategory;

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  late TicketCategory? _category = widget.initialCategory;
  Property? _home;
  String? _location;
  TicketPriority _priority = TicketPriority.normal;
  final _title = TextEditingController();
  final _details = TextEditingController();
  final List<String> _photos = [];
  bool _busy = false;
  Ticket? _created;

  static const _locations = ['loc_kitchen', 'loc_bathroom', 'loc_bedroom', 'loc_living', 'loc_outside'];

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  bool get _valid =>
      _home != null && _category != null && _location != null && _details.text.trim().length >= 4;

  Future<void> _addPhoto() async {
    final source = await showAppSheet<ImageSource>(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: ctx.tr('camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: ctx.tr('gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1600);
      if (file != null) setState(() => _photos.add(file.path));
    } catch (_) {
      // No camera (simulator) or permission denied: fall back to a demo photo
      // so the flow can still be tried.
      setState(() => _photos.add('assets/photos/interior-${(_photos.length % 4) + 1}.jpg'));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final title = _title.text.trim().isEmpty ? context.categoryLabel(_category!) : _title.text.trim();
    final t = await context.appRead.createTicket(
      title: title,
      description: _details.text.trim(),
      category: _category!,
      priority: _priority,
      location: context.tr(_location!),
      photos: List.of(_photos),
      home: _home!,
    );
    if (mounted) setState(() => _created = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: SuccessView(
              title: context.tr('request_sent'),
              body: context.tr('request_sent_sub', {'n': _created!.number, 'agency': context.app.agencyName}),
              primary: context.tr('done'),
              onPrimary: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    final homes = context.app.currentHomes;
    final lease = context.app.lease;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.close_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('new_request')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              children: [
                _label(context.tr('which_home')),
                if (homes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_work_outlined, color: AppColors.ink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('no_home_repair'),
                            style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final h in homes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HomeTile(
                        home: h,
                        subtitle: lease != null && lease.property.id == h.id
                            ? context.tr('home_lease')
                            : context.tr('home_stay', {
                                'date': context.date(
                                  context.app.stays.firstWhere((s) => s.property.id == h.id).checkOut,
                                ),
                              }),
                        selected: _home?.id == h.id,
                        onTap: () => setState(() => _home = h),
                      ),
                    ),
                const SizedBox(height: 26),
                _label(context.tr('what_wrong')),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    for (final c in TicketCategory.values)
                      _CategoryTile(category: c, selected: _category == c, onTap: () => setState(() => _category = c)),
                  ],
                ),
                const SizedBox(height: 26),
                _label(context.tr('where')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in _locations)
                      ChoiceChipPill(
                        label: context.tr(l),
                        dense: true,
                        selected: _location == l,
                        onTap: () => setState(() => _location = l),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                _label(context.tr('short_title')),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(hintText: context.tr('title_hint')),
                ),
                const SizedBox(height: 18),
                _label(context.tr('describe')),
                TextField(
                  controller: _details,
                  onChanged: (_) => setState(() {}),
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: context.tr('describe_hint')),
                ),
                const SizedBox(height: 26),
                _label(context.tr('add_photos')),
                SizedBox(
                  height: 92,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: _addPhoto,
                        child: Container(
                          width: 92,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.silver, width: 1.4),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: AppColors.ink, size: 28),
                        ),
                      ),
                      for (var i = 0; i < _photos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: SizedBox(width: 92, height: 92, child: ticketImage(_photos[i])),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAction(
                                  icon: Icons.close_rounded,
                                  size: 26,
                                  onTap: () => setState(() => _photos.removeAt(i)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(context.tr('photos_help'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 26),
                _label(context.tr('how_urgent')),
                Row(
                  children: [
                    for (final p in TicketPriority.values) ...[
                      if (p != TicketPriority.normal) const SizedBox(width: 8),
                      Expanded(
                        child: _PriorityTile(
                          priority: p,
                          selected: _priority == p,
                          onTap: () => setState(() => _priority = p),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(context.tr('urgent_hint'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              child: PillButton(
                icon: Icons.send_rounded,
                label: context.tr('send_request'),
                loading: _busy,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.home, required this.subtitle, required this.selected, required this.onTap});
  final Property home;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 54,
              height: 54,
              child: home.photos.isEmpty ? const ColoredBox(color: AppColors.line) : AppImage(home.cover, cacheWidth: 200),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: selected ? AppColors.white : AppColors.onyx,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: selected ? AppColors.white.withValues(alpha: 0.75) : AppColors.muted),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.white : AppColors.silver,
          ),
        ],
      ),
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});
  final TicketCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(categoryIcons[category], color: selected ? AppColors.white : AppColors.ink, size: 26),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              context.categoryLabel(category),
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.onyx,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({required this.priority, required this.selected, required this.onTap});
  final TicketPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TicketPriority.normal => AppColors.ink,
      TicketPriority.high => AppColors.ink,
      TicketPriority.urgent => AppColors.ink,
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? color : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 6,
                  height: 8.0 + i * 4,
                  decoration: BoxDecoration(
                    color: i <= priority.index ? color : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.priorityLabel(priority),
              style: TextStyle(fontWeight: FontWeight.w600, color: selected ? color : AppColors.onyx, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.white),
    ),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
