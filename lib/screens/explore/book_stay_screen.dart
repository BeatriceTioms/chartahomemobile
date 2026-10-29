import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/month_calendar.dart';
import 'stay_review_screen.dart';

/// Short stay: any number of nights (1, 3, 7 and 14 as shortcuts), a
/// check-in day from the agency's free nights, the price for that duration,
/// then book and pay in one step through PayUnit.
class BookStayScreen extends StatefulWidget {
  const BookStayScreen({super.key, required this.property});
  final Property property;

  @override
  State<BookStayScreen> createState() => _BookStayScreenState();
}

class _BookStayScreenState extends State<BookStayScreen> {
  static const _shortcuts = [1, 3, 7, 14, 28];

  int _nights = 3;
  late DateTime? _checkIn = context.appRead.nextFreeCheckIn(p, nights: 1);

  Property get p => widget.property;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _nightsLabel(int n) => context.tr(n == 1 ? 'night_one' : 'nights', {'n': n});

  void _setNights(int n) {
    HapticFeedback.selectionClick();
    setState(() => _nights = n.clamp(1, AppState.maxStayNights));
  }

  void _review() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StayReviewScreen(property: p, checkIn: _checkIn!, nights: _nights),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = context.app;

    final checkIn = _checkIn;
    final quote = p.quote(_nights);
    final free = checkIn == null ? 0 : app.freeNightsFrom(p, checkIn);
    final clash = checkIn == null ? null : app.firstUnavailableNight(p, checkIn, _nights);
    final available = checkIn != null && clash == null;

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
        title: Text(context.tr('book_stay')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _header(),
                const SizedBox(height: 26),
                Text(context.tr('how_many_nights'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _NightsStepper(value: _nights, label: _nightsLabel(_nights), onChanged: _setNights),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in _shortcuts)
                      ChoiceChipPill(
                        label: _nightsLabel(n),
                        dense: true,
                        selected: _nights == n,
                        onTap: () => _setNights(n),
                      ),
                  ],
                ),
                if (p.packageNights.length > 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.tr('packages_hint', {
                      'list': p.packageNights
                          .where((n) => n > 1)
                          .map((n) => '${_nightsLabel(n)} ${context.money(p.stayRates[n]!, compact: true)}')
                          .join(' · '),
                    }),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                  ),
                ],
                const SizedBox(height: 26),
                Text(context.tr('check_in_date'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(context.tr('calendar_legend'), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: MonthCalendar(
                    firstDate: _today,
                    selected: checkIn,
                    rangeNights: _nights,
                    isUnavailable: (d) => !app.isNightFree(p, d),
                    onSelected: (d) => setState(() => _checkIn = d),
                  ),
                ),
                const SizedBox(height: 14),
                if (checkIn != null && !available)
                  _Notice(
                    text: context.tr('stay_too_long', {'date': context.dateShort(clash!), 'n': _nightsLabel(free)}),
                    action: free > 0 ? context.tr('use_n_nights', {'n': _nightsLabel(free)}) : null,
                    onAction: free > 0 ? () => _setNights(free) : null,
                  )
                else if (checkIn != null)
                  _summary(checkIn, quote),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: PillButton(
                color: AppColors.brand,
                label: available
                    ? context.tr('review_booking', {'amount': context.money(quote.total)})
                    : context.tr('pick_free_dates'),
                onPressed: available ? _review : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AppImage(p.cover, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 200),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
            const SizedBox(height: 2),
            Text(p.address, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              '${context.money(p.nightlyRate ?? 0)}${context.tr('per_night')}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _summary(DateTime checkIn, StayQuote quote) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        KeyValueRow(
          label: context.tr('check_in'),
          value: '${context.weekdayDate(checkIn)} · ${context.tr('check_in_time')}',
        ),
        KeyValueRow(
          label: context.tr('check_out'),
          value: '${context.weekdayDate(checkIn.add(Duration(days: _nights)))} · ${context.tr('check_out_time')}',
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
        KeyValueRow(
          label: '${_nightsLabel(_nights)} × ${context.money(p.nightlyRate ?? 0)}',
          value: context.money(quote.subtotal),
        ),
        if (quote.discount > 0)
          KeyValueRow(
            label: context.tr('package_saving', {'n': _nightsLabel(quote.packageNights!)}),
            value: '− ${context.money(quote.discount)}',
          ),
        KeyValueRow(label: context.tr('stay_total'), value: context.money(quote.total), bold: true),
      ],
    ),
  );
}

/// − [n nights] + with large round buttons.
class _NightsStepper extends StatelessWidget {
  const _NightsStepper({required this.value, required this.label, required this.onChanged});
  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        CircleAction(icon: Icons.remove_rounded, size: 48, onTap: value > 1 ? () => onChanged(value - 1) : null),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
        ),
        CircleAction(
          icon: Icons.add_rounded,
          size: 48,
          color: AppColors.white,
          background: AppColors.brand,
          onTap: value < AppState.maxStayNights ? () => onChanged(value + 1) : null,
        ),
      ],
    ),
  );
}

/// Calm inline message with an optional fix, e.g. "Book 3 nights instead".
class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.ink),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.event_busy_rounded, size: 20, color: AppColors.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500)),
              if (action != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
