import '../data/models.dart';

enum SocialProvider { google, apple }

enum PaymentKind { rent, stay, booking }

/// A PayUnit transaction opened by the web app for this resident.
class CheckoutSession {
  const CheckoutSession({required this.reference, required this.amount, this.checkoutUrl});

  /// Our transaction id (prefix + hex, like the web's newTransactionId).
  final String reference;
  final int amount;

  /// PayUnit's hosted page. Null in demo mode, where nothing is opened.
  final Uri? checkoutUrl;
}

enum PaymentOutcome { paid, pending, failed, cancelled }

/// What the resident sees after signing in.
class ResidentSnapshot {
  const ResidentSnapshot({
    required this.user,
    required this.lease,
    required this.charges,
    required this.payments,
    required this.tickets,
    required this.notices,
    required this.stays,
  });

  final UserProfile user;
  final Lease? lease;
  final List<RentCharge> charges;
  final List<Payment> payments;
  final List<Ticket> tickets;
  final List<Notice> notices;
  final List<StayBooking> stays;
}

class BackendException implements Exception {
  BackendException(this.key, [this.detail]);

  /// A strings.dart key the screens can show as is.
  final String key;
  final String? detail;

  @override
  String toString() => 'BackendException($key${detail == null ? '' : ': $detail'})';
}

/// Everything the app asks of the server. [MockBackend] answers from demo
/// data; [SupabaseBackend] talks to the Charta Home Supabase project and the
/// web app's /api/mobile routes. Screens never call either directly, only
/// through AppState.
abstract class ChartaBackend {
  bool get isDemo;

  Future<void> init();

  // ---- auth (errors are strings.dart keys, null on success) -------------
  bool get hasSession;
  Future<String?> signIn(String email, String password);
  Future<String?> signUp({required String name, required String email, required String password});
  Future<String?> signInWithProvider(SocialProvider provider);
  Future<void> requestPasswordReset(String email);
  Future<String?> verifyResetCode(String email, String code);
  Future<String?> updatePassword(String email, String password);
  Future<void> signOut();

  /// Deletes the signed-in account (App Store and Google Play rule). What the
  /// agency must keep stays with it, unlinked. Throws [BackendException].
  Future<void> deleteAccount();

  // ---- data ------------------------------------------------------------
  Future<ResidentSnapshot> loadResident();
  Future<List<Property>> listings();

  /// Nights already taken on the agencies' calendars (the `stays` table),
  /// without any guest details.
  Future<List<AgencyBlock>> takenNights(List<String> propertyIds);

  // ---- actions ---------------------------------------------------------
  /// Holds the dates and returns the server's price for them. Throws
  /// [StayClash] when a night was taken meanwhile.
  Future<StayBooking> bookStay(
    Property p, {
    required DateTime checkIn,
    required int nights,
    required PaymentMethod method,
  });

  Future<CheckoutSession> startPayment({
    required PaymentKind kind,
    required PaymentMethod method,
    List<String> chargeIds = const [],
    String? stayId,
    String? leaseRequestId,
  });

  /// Asks the web app, which asks PayUnit. Never trusts the return URL alone.
  Future<PaymentOutcome> paymentStatus(String reference);

  Future<int> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    required String location,
    required List<String> photoPaths,
    required String propertyId,
  });

  Future<void> sendTicketMessage(String ticketId, String body);

  Future<void> requestLease(Property p, {required DateTime moveIn, required int months});

  /// Holds a monthly rental for 15 minutes while the first month and the
  /// deposit are paid. Throws [BackendException] `err_unit_taken` (with the
  /// first free day as detail) when those months are no longer free.
  Future<LeaseHold> bookLease(Property p, {required DateTime moveIn, required int months});

  /// Saves this device so the server can send push notifications.
  Future<void> registerDevice({required String platform, String? pushToken, required String locale});
}

class StayClash implements Exception {
  StayClash(this.night);
  final DateTime night;
}
