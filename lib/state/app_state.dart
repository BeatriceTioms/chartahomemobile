import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import '../backend/checkout.dart';
import '../backend/mock_backend.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../services/notifications.dart';

/// Single source of truth for the signed-in resident.
///
/// Screens read and change state only through here; every call to the
/// server goes through [backend] ([MockBackend] for the demo,
/// SupabaseBackend in production).
class AppState extends ChangeNotifier {
  AppState({String? lang, ChartaBackend? backend})
    : _lang = Strings.supported.contains(lang) ? lang! : 'fr',
      backend = backend ?? MockBackend() {
    if (this.backend.isDemo) _seed();
  }

  final ChartaBackend backend;

  String _lang;
  String get lang => _lang;
  Strings get strings => Strings(_lang);
  void setLang(String value) {
    if (value == _lang) return;
    _lang = value;
    _save((p) => p.setString(_kLang, value));
    _syncNews();
    notifyListeners();
  }

  bool onboarded = false;
  bool signedIn = false;
  bool notificationsAsked = false;

  /// "Keep me signed in". When off, the session is closed on next launch.
  bool keepSignedIn = true;

  UserProfile user = UserProfile(name: '', phone: '', email: '', photo: '');
  Lease? lease;
  List<RentCharge> charges = [];
  List<Payment> payments = [];
  List<Ticket> tickets = [];
  List<Notice> notices = [];
  List<Property> properties = [];
  final Set<String> saved = {};
  final List<Visit> visits = [];
  final List<RentalApplication> applications = [];
  List<StayBooking> stays = [];
  List<AgencyBlock> agencyBlocks = [];

  DateTime get today => DateTime.now();
  String get currency => lease?.currency ?? 'XAF';
  String get agencyName => lease?.property.agency ?? 'Charta Immobilier';

  void _seed() {
    final now = DateTime.now();
    properties = MockData.properties;
    agencyBlocks = MockData.agencyBlocks(now);
    saved.add('p2');
    user = MockData.user();
    lease = MockData.lease();
    charges = MockData.charges(now);
    payments = MockData.payments(charges);
    tickets = MockData.tickets(now);
    notices = MockData.notices(now);
    visits.add(
      Visit(
        id: 'v1',
        property: properties[1],
        at: DateTime(now.year, now.month, now.day + 3, 15),
        status: VisitStatus.confirmed,
      ),
    );
  }

  // ---- session ----------------------------------------------------------

  static const _kOnboarded = 'onboarded';
  static const _kNotificationsAsked = 'notifications_asked';
  static const _kKeepSignedIn = 'keep_signed_in';
  static const _kLang = 'lang';

  /// Restores the session and loads what the app needs. Called once at
  /// launch, before the first frame of real content.
  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onboarded = prefs.getBool(_kOnboarded) ?? onboarded;
      notificationsAsked = prefs.getBool(_kNotificationsAsked) ?? notificationsAsked;
      keepSignedIn = prefs.getBool(_kKeepSignedIn) ?? true;
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      newsEnabled = prefs.getBool('news_notifications') ?? true;
      final l = prefs.getString(_kLang);
      if (l != null && Strings.supported.contains(l)) _lang = l;
    } catch (_) {
      // No storage (tests): start fresh.
    }
    await backend.init();
    // Offline or server down: still open the app, with what we have.
    try {
      if (backend.hasSession) {
        if (keepSignedIn) {
          signedIn = true;
          await refresh();
        } else {
          await backend.signOut();
        }
      }
      if (!backend.isDemo) await loadListings();
    } catch (e) {
      debugPrint('bootstrap: $e');
    }
    // Keeps the news scheduled two weeks ahead from every launch.
    _syncNews();
    notifyListeners();
  }

  Future<void> _save(void Function(SharedPreferences p) write) async {
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// Pulls the resident's home, rent, repairs and stays from the server.
  Future<void> refresh() async {
    if (backend.isDemo) return;
    final s = await backend.loadResident();
    user = s.user;
    lease = s.lease;
    charges = s.charges;
    payments = s.payments;
    tickets = s.tickets;
    notices = s.notices;
    stays = s.stays;
    notifyListeners();
  }

  Future<void> loadListings() async {
    properties = await backend.listings();
    agencyBlocks = await backend.takenNights([
      for (final p in properties)
        if (p.shortStay) p.id,
    ]);
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    _save((p) => p.setBool(_kOnboarded, true));
    notifyListeners();
  }

  bool notificationsEnabled = false;

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    _save((p) => p.setBool('notifications_enabled', value));
    _syncNews();
  }

  /// Charta Home news twice a day (new homes, offers, tips). Opted into on
  /// the notifications screen, switched off any time in Profile.
  bool newsEnabled = true;
  static const newsCount = 10;

  void setNewsEnabled(bool value) {
    newsEnabled = value;
    _save((p) => p.setBool('news_notifications', value));
    _syncNews();
    notifyListeners();
  }

  Future<void> _syncNews() async {
    try {
      if (notificationsEnabled && newsEnabled) {
        await NotificationService.instance.scheduleNews([
          for (var i = 1; i <= newsCount; i++) (strings.t('news_${i}_t'), strings.t('news_${i}_b')),
        ]);
      } else {
        await NotificationService.instance.cancelNews();
      }
    } catch (e) {
      // No notification plugin (tests, desktop).
      debugPrint('news: $e');
    }
  }

  /// Saves a push token (from Firebase Cloud Messaging, once added) so the
  /// server can reach this device.
  void registerPushToken(String token) => _registerDevice(pushToken: token);

  void markNotificationsAsked() {
    notificationsAsked = true;
    _save((p) => p.setBool(_kNotificationsAsked, true));
    notifyListeners();
  }

  void setKeepSignedIn(bool value) {
    keepSignedIn = value;
    _save((p) => p.setBool(_kKeepSignedIn, value));
  }

  /// Same accounts as the web app (Supabase auth, email + password). Each
  /// call returns null on success or a strings.dart key to show.
  Future<String?> signIn(String email, String password) async {
    final error = await backend.signIn(email, password);
    if (error == null) await _enter();
    return error;
  }

  Future<String?> signUp({required String name, required String email, required String password}) async {
    final error = await backend.signUp(name: name, email: email, password: password);
    if (error != null) return error;
    if (backend.isDemo) {
      user
        ..name = name.trim()
        ..email = email.trim().toLowerCase();
    }
    await _enter();
    return null;
  }

  Future<String?> signInWithProvider(SocialProvider provider) async {
    final error = await backend.signInWithProvider(provider);
    // On a real device the provider finishes in the browser and Supabase
    // reports the session through onAuthStateChange (see main.dart).
    if (error == null && backend.isDemo) await _enter();
    return error;
  }

  /// Called when Supabase reports a new session from a deep link (social
  /// sign-in or email confirmation).
  Future<void> onSessionRestored() async {
    if (!signedIn) await _enter();
  }

  Future<void> _enter() async {
    signedIn = true;
    try {
      await refresh();
    } catch (e) {
      // Signed in but the data did not load: show the app, it retries on
      // the next refresh.
      debugPrint('refresh after sign-in: $e');
    }
    notifyListeners();
    _registerDevice();
  }

  /// Never reveals whether the email has an account.
  Future<void> requestPasswordReset(String email) => backend.requestPasswordReset(email);

  Future<String?> verifyResetCode(String email, String code) => backend.verifyResetCode(email, code);

  Future<String?> updatePassword(String email, String password) => backend.updatePassword(email, password);

  void signOut() {
    signedIn = false;
    backend.signOut();
    notifyListeners();
  }

  /// Deletes the account on the server, then leaves like a sign-out.
  /// Throws [BackendException] (e.g. `err_delete_staff`), leaving the user in.
  Future<void> deleteAccount() async {
    await backend.deleteAccount();
    signedIn = false;
    saved.clear();
    notifyListeners();
  }

  void _registerDevice({String? pushToken}) {
    backend
        .registerDevice(platform: Platform.isIOS ? 'ios' : 'android', pushToken: pushToken, locale: _lang)
        .catchError((_) {});
  }

  // ---- explore ----------------------------------------------------------

  bool isSaved(Property p) => saved.contains(p.id);

  void toggleSaved(Property p) {
    saved.contains(p.id) ? saved.remove(p.id) : saved.add(p.id);
    notifyListeners();
  }

  List<Property> get savedProperties => properties.where(isSaved).toList();

  Future<Visit> requestVisit(Property p, DateTime at) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final v = Visit(id: 'v${visits.length + 1}', property: p, at: at);
    visits.add(v);
    visits.sort((a, b) => a.at.compareTo(b.at));
    notices.insert(
      0,
      Notice(
        kind: NoticeKind.visit,
        title: 'visit_requested',
        body: '${p.title} · ${p.agent.name}',
        at: DateTime.now(),
      ),
    );
    notifyListeners();
    return v;
  }

  Future<RentalApplication> apply(
    Property p, {
    required DateTime moveIn,
    required int months,
    int occupants = 1,
  }) async {
    await backend.requestLease(p, moveIn: moveIn, months: months);
    final a = RentalApplication(
      id: 'a${applications.length + 1}',
      property: p,
      moveIn: moveIn,
      months: months,
      occupants: occupants,
      submittedAt: DateTime.now(),
    );
    applications.insert(0, a);
    notifyListeners();
    return a;
  }

  /// Holds the dates on the agency's calendar. The server re-checks
  /// availability and prices the stay from the agency's packages; a clash
  /// throws [StayUnavailable]. The hold lapses if it is not paid in time.
  Future<StayBooking> holdStay(
    Property p, {
    required DateTime checkIn,
    required int nights,
    required PaymentMethod method,
  }) async {
    final clash = firstUnavailableNight(p, checkIn, nights);
    if (clash != null) throw StayUnavailable(clash);
    final StayBooking booking;
    try {
      booking = await backend.bookStay(p, checkIn: checkIn, nights: nights, method: method);
    } on StayClash catch (e) {
      // Someone took a night meanwhile: refresh the calendar for next time.
      agencyBlocks = await backend.takenNights([p.id]) + agencyBlocks.where((b) => b.propertyId != p.id).toList();
      notifyListeners();
      throw StayUnavailable(e.night);
    }
    stays.add(booking);
    stays.sort((x, y) => x.checkIn.compareTo(y.checkIn));
    notifyListeners();
    return booking;
  }

  /// Pays a held stay through PayUnit. Safe to call again after a
  /// cancelled or failed attempt; the dates stay held meanwhile.
  Future<void> payStay(StayBooking booking, PaymentMethod method) async {
    final session = await backend.startPayment(kind: PaymentKind.stay, method: method, stayId: booking.id);
    final outcome = await runCheckout(backend, session);
    if (outcome != PaymentOutcome.paid) throw PaymentNotCompleted(outcome);
    await refresh();
  }

  /// Hold and pay in one go.
  Future<StayBooking> bookStay(
    Property p, {
    required DateTime checkIn,
    required int nights,
    required PaymentMethod method,
  }) async {
    final booking = await holdStay(p, checkIn: checkIn, nights: nights, method: method);
    await payStay(booking, method);
    return booking;
  }

  /// How long the server holds unpaid dates (see book_stay in the migration).
  static const holdMinutes = 15;

  // ---- availability (from the agency's calendar) ----------------------

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whether [night] (sleeping from that day to the next) is free for a
  /// short stay at [p]: not in the past, not closed by the agency and not
  /// already booked.
  bool isNightFree(Property p, DateTime night) {
    final n = _day(night);
    if (!p.shortStay || n.isBefore(_day(today))) return false;
    if (agencyBlocks.any((b) => b.propertyId == p.id && b.covers(n))) return false;
    for (final s in stays.where((s) => s.property.id == p.id)) {
      final start = _day(s.checkIn);
      if (!n.isBefore(start) && n.isBefore(start.add(Duration(days: s.nights)))) return false;
    }
    return true;
  }

  /// First night of the stay that is not free, or null when all are.
  DateTime? firstUnavailableNight(Property p, DateTime checkIn, int nights) {
    for (var i = 0; i < nights; i++) {
      final n = _day(checkIn).add(Duration(days: i));
      if (!isNightFree(p, n)) return n;
    }
    return null;
  }

  /// How many nights in a row can be booked starting on [checkIn].
  int freeNightsFrom(Property p, DateTime checkIn, {int max = maxStayNights}) {
    var n = 0;
    while (n < max && isNightFree(p, _day(checkIn).add(Duration(days: n)))) {
      n++;
    }
    return n;
  }

  /// Earliest day a short stay of [nights] can start, within the next year.
  DateTime? nextFreeCheckIn(Property p, {int nights = 1}) {
    for (var i = 0; i < 365; i++) {
      final d = _day(today).add(Duration(days: i));
      if (firstUnavailableNight(p, d, nights) == null) return d;
    }
    return null;
  }

  /// Holds a monthly rental, then pays the first month and the deposit
  /// through PayUnit. Pass [hold] to retry paying the same hold.
  Future<LeaseHold> bookLease(
    Property p, {
    required DateTime moveIn,
    required int months,
    required PaymentMethod method,
    LeaseHold? hold,
    void Function(LeaseHold hold)? onHeld,
  }) async {
    final h = hold ?? await backend.bookLease(p, moveIn: moveIn, months: months);
    onHeld?.call(h);
    final session = await backend.startPayment(kind: PaymentKind.booking, method: method, leaseRequestId: h.id);
    final outcome = await runCheckout(backend, session);
    if (outcome != PaymentOutcome.paid) throw PaymentNotCompleted(outcome);
    applications.insert(
      0,
      RentalApplication(
        id: h.id,
        property: p,
        moveIn: moveIn,
        months: months,
        occupants: 1,
        submittedAt: DateTime.now(),
        status: ApplicationStatus.reserved,
      ),
    );
    notifyListeners();
    return h;
  }

  /// Long-term move-in: on or after the agency's "available from" date and
  /// not on a night the agency has closed.
  bool canMoveIn(Property p, DateTime day) {
    final d = _day(day);
    if (d.isBefore(_day(today)) || d.isBefore(_day(p.availableFrom))) return false;
    return !agencyBlocks.any((b) => b.propertyId == p.id && b.covers(d));
  }

  static const maxStayNights = 30;

  List<StayBooking> get upcomingStays => stays.where((s) => s.checkOut.isAfter(today)).toList();

  List<Visit> get upcomingVisits =>
      visits.where((v) => v.at.isAfter(today) && v.status != VisitStatus.cancelled).toList();

  // ---- rent -------------------------------------------------------------

  List<RentCharge> get unpaidCharges =>
      charges.where((c) => c.balance > 0).toList()..sort((a, b) => a.dueOn.compareTo(b.dueOn));

  /// Charges that are due now: overdue, or due within the current period.
  List<RentCharge> get dueCharges => unpaidCharges.where((c) => !c.periodStart.isAfter(today)).toList();

  /// What can be paid now: everything unpaid, plus future months up to
  /// [ahead] months from today so rent can be paid in advance. Future months
  /// are only added to [charges] once they are paid.
  List<RentCharge> payableCharges({int ahead = 6}) {
    final list = unpaidCharges;
    final lease = this.lease;
    if (lease == null) return list;
    final last = charges.map((c) => c.periodStart).reduce((a, b) => a.isAfter(b) ? a : b);
    var month = DateTime(last.year, last.month + 1);
    final limit = DateTime(today.year, today.month + ahead);
    while (!month.isAfter(limit)) {
      list.add(
        RentCharge(
          // A month not yet issued: the server creates the rent charge
          // when this "adv:" period is paid.
          id: 'adv:${month.year}-${month.month.toString().padLeft(2, '0')}-01',
          periodStart: month,
          periodEnd: DateTime(month.year, month.month + 1, 0),
          dueOn: DateTime(month.year, month.month, lease.dueDay),
          amount: lease.rent,
        ),
      );
      month = DateTime(month.year, month.month + 1);
    }
    return list;
  }

  RentCharge? get nextCharge => unpaidCharges.isEmpty ? null : unpaidCharges.first;

  int get balanceDue => dueCharges.fold(0, (sum, c) => sum + c.balance);

  int get paidThisYear => payments.where((p) => p.paidOn.year == today.year).fold(0, (sum, p) => sum + p.amount);

  /// Talks to PayUnit through the Charta Home backend. The app never holds
  /// gateway credentials: the backend opens the transaction, the resident
  /// picks MTN MoMo or Orange Money (or enters a card) and their number on
  /// PayUnit's hosted page, and the backend confirms by asking PayUnit for
  /// the status (see lib/payunit.ts in the SaaS).
  Future<Payment> pay(List<RentCharge> selected, PaymentMethod method) async {
    final session = await backend.startPayment(
      kind: PaymentKind.rent,
      method: method,
      chargeIds: [for (final c in selected) c.id],
    );
    final outcome = await runCheckout(backend, session);
    if (outcome != PaymentOutcome.paid) throw PaymentNotCompleted(outcome);
    final amount = selected.fold<int>(0, (s, c) => s + c.balance);
    for (final c in selected) {
      if (!charges.contains(c)) charges.add(c);
      c.paid = c.amount;
    }
    final payment = Payment(
      id: 'pay${payments.length + 1}',
      amount: amount,
      paidOn: DateTime.now(),
      method: method,
      reference: session.reference,
      periods: selected.map((c) => c.periodStart).toList(),
    );
    payments.insert(0, payment);
    notices.removeWhere((n) => n.kind == NoticeKind.rent && !n.read);
    notifyListeners();
    await refresh();
    return payment;
  }

  // ---- maintenance ------------------------------------------------------

  List<Ticket> get openTickets => tickets.where((t) => t.isOpen).toList();
  List<Ticket> get closedTickets => tickets.where((t) => !t.isOpen).toList();

  /// The homes a repair can be reported on: the one leased, and any paid
  /// stay running today. The server accepts no other.
  List<Property> get currentHomes {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final homes = <Property>[if (lease != null) lease!.property];
    for (final s in stays) {
      final from = DateTime(s.checkIn.year, s.checkIn.month, s.checkIn.day);
      final to = DateTime(s.checkOut.year, s.checkOut.month, s.checkOut.day);
      if (!day.isBefore(from) && !day.isAfter(to) && homes.every((h) => h.id != s.property.id)) {
        homes.add(s.property);
      }
    }
    return homes;
  }

  Future<Ticket> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    required String location,
    required List<String> photos,
    required Property home,
  }) async {
    final number = await backend.createTicket(
      title: title,
      description: description,
      category: category,
      priority: priority,
      location: location,
      photoPaths: photos,
      propertyId: home.id,
    );
    final t = Ticket(
      id: 't$number',
      number: number,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: TicketStatus.newTicket,
      openedAt: DateTime.now(),
      location: location,
      photos: photos,
      messages: [TicketMessage(fromMe: true, body: description, at: DateTime.now())],
    );
    tickets.insert(0, t);
    notifyListeners();
    return t;
  }

  void sendMessage(Ticket t, String body) {
    t.messages.add(TicketMessage(fromMe: true, body: body, at: DateTime.now()));
    backend.sendTicketMessage(t.id, body).catchError((_) {});
    notifyListeners();
  }

  void confirmResolved(Ticket t) {
    t.status = TicketStatus.resolved;
    t.resolvedAt = DateTime.now();
    notifyListeners();
  }

  void rate(Ticket t, int stars) {
    t.rating = stars;
    notifyListeners();
  }

  // ---- notifications ----------------------------------------------------

  int get unreadCount => notices.where((n) => !n.read).length;

  void markRead(Notice n) {
    n.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notices) {
      n.read = true;
    }
    notifyListeners();
  }
}

class PaymentNotCompleted implements Exception {
  PaymentNotCompleted(this.outcome);
  final PaymentOutcome outcome;
}

class StayUnavailable implements Exception {
  StayUnavailable(this.night);
  final DateTime night;
}

/// Makes [AppState] available to the tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);

  /// For initState, field initialisers and callbacks: reads without listening.
  AppState get appRead => AppScope.read(this);
  String tr(String key, [Map<String, Object>? args]) => AppScope.of(this).strings.t(key, args);
}
