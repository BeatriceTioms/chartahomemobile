import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../state/app_state.dart';

/// Money is stored in whole units of the agency currency (bigint in the SaaS).
String money(int amount, String currency, {bool compact = false}) {
  final symbol = switch (currency) {
    'XAF' || 'XOF' => 'FCFA',
    'GNF' => 'GNF',
    'EUR' => '€',
    'USD' => r'$',
    _ => currency,
  };
  if (compact && amount >= 1000000) {
    final m = amount / 1000000;
    return '${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)}M $symbol';
  }
  final n = NumberFormat.decimalPattern('fr').format(amount).replaceAll(' ', ' ').replaceAll(' ', ' ');
  return '$n $symbol';
}

extension FormatContext on BuildContext {
  String get _locale => app.lang;

  String money(int amount, {bool compact = false}) => _moneyFn(amount, app.currency, compact: compact);

  String date(DateTime d) => DateFormat('d MMM y', _locale).format(d);
  String dateShort(DateTime d) => DateFormat('d MMM', _locale).format(d);
  String month(DateTime d) => toBeginningOfSentenceCase(DateFormat('MMMM y', _locale).format(d));
  String weekdayDate(DateTime d) => toBeginningOfSentenceCase(DateFormat('EEE d MMM', _locale).format(d));
  String time(DateTime d) => DateFormat('HH:mm', _locale).format(d);

  String dayLabel(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return tr('today');
    if (diff == 1) return tr('tomorrow');
    if (diff == -1) return tr('yesterday');
    return weekdayDate(d);
  }

  String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return tr('just_now');
    if (diff.inHours < 1) return tr('minutes_ago', {'n': diff.inMinutes});
    if (diff.inDays < 1) return tr('hours_ago', {'n': diff.inHours});
    if (diff.inDays == 1) return tr('yesterday').toLowerCase();
    if (diff.inDays < 7) return tr('days_ago', {'n': diff.inDays});
    return dateShort(d);
  }

  String kindLabel(PropertyKind k) => tr(k.name);
  String cycleLabel(LeaseCycle c) => tr('cycle_${c.name}');

  String methodLabel(PaymentMethod m) => tr(switch (m) {
    PaymentMethod.mobileMoney => 'mobile_money',
    PaymentMethod.mtnMomo => 'mtn_momo',
    PaymentMethod.orangeMoney => 'orange_money',
    PaymentMethod.card => 'card',
    PaymentMethod.bankTransfer => 'bank_transfer',
    PaymentMethod.cash => 'cash',
  });

  String statusLabel(TicketStatus s) => tr(switch (s) {
    TicketStatus.newTicket => 'st_new',
    TicketStatus.assigned => 'st_assigned',
    TicketStatus.inProgress => 'st_in_progress',
    TicketStatus.resolved => 'st_resolved',
    TicketStatus.cancelled => 'st_cancelled',
  });

  String categoryLabel(TicketCategory c) => tr('cat_${c.name}');
  String priorityLabel(TicketPriority p) => tr('pr_${p.name}');

  String beds(int n) => tr(n == 1 ? 'bed' : 'beds', {'n': n});
  String baths(int n) => tr(n == 1 ? 'bath' : 'baths', {'n': n});
}

String _moneyFn(int amount, String currency, {bool compact = false}) => money(amount, currency, compact: compact);
