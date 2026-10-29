import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Month grid of round day bubbles (reference 4). Days before [firstDate],
/// and days [isUnavailable] rejects (the agency's calendar), are struck
/// through and cannot be picked. [rangeNights] tints the nights after the
/// selected day, to show a stay.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.firstDate,
    this.isUnavailable,
    this.rangeNights = 1,
  });
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final DateTime firstDate;
  final bool Function(DateTime day)? isUnavailable;
  final int rangeNights;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(
    (widget.selected ?? widget.firstDate).year,
    (widget.selected ?? widget.firstDate).month,
  );

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final lang = context.app.lang;
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday first
    final canGoBack = _month.isAfter(DateTime(first.year, first.month));
    final weekdays = List.generate(
      7,
      (i) => DateFormat.E(lang).format(DateTime(2023, 1, 1 + i)).substring(0, 1).toUpperCase(),
    );

    return Column(
      children: [
        Row(
          children: [
            Text(
              toBeginningOfSentenceCase(DateFormat('MMMM y', lang).format(_month)),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            CircleAction(
              icon: Icons.chevron_left_rounded,
              size: 38,
              background: AppColors.white,
              onTap: canGoBack ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
            ),
            const SizedBox(width: 8),
            CircleAction(
              icon: Icons.chevron_right_rounded,
              size: 38,
              background: AppColors.white,
              onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leading + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (_, i) {
            if (i < leading) return const SizedBox();
            final day = DateTime(_month.year, _month.month, i - leading + 1);
            final past = day.isBefore(first);
            final taken = !past && (widget.isUnavailable?.call(day) ?? false);
            final disabled = past || taken;
            final selected = widget.selected != null && _same(day, widget.selected!);
            final sel = widget.selected;
            final inRange =
                sel != null &&
                !selected &&
                !disabled &&
                day.isAfter(sel) &&
                day.isBefore(DateTime(sel.year, sel.month, sel.day + widget.rangeNights));
            final today = _same(day, DateTime.now());
            return GestureDetector(
              onTap: disabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onSelected(day);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.ink
                      : inRange
                      ? AppColors.azure100
                      : (disabled ? Colors.transparent : AppColors.white),
                  border: today && !selected ? Border.all(color: AppColors.ink, width: 1.2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.white
                        : (disabled ? AppColors.faint.withValues(alpha: 0.6) : AppColors.onyx),
                    decoration: taken ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.faint,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
