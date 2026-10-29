import 'dart:math';

import '../data/mock_data.dart';
import '../data/models.dart';
import 'backend.dart';

/// Demo backend: answers from MockData with short delays, so every screen
/// can be tried without a server. Used whenever env values are missing.
class MockBackend implements ChartaBackend {
  final Map<String, String> _accounts = {MockData.demoEmail: MockData.demoPassword};
  final _rnd = Random();
  int _ticketNumber = 1042;
  String? _current;

  static String _norm(String email) => email.trim().toLowerCase();
  static Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  String _ref(String prefix) => '$prefix${List.generate(8, (_) => '0123456789ABCDEF'[_rnd.nextInt(16)]).join()}';

  @override
  bool get isDemo => true;

  @override
  Future<void> init() async {}

  @override
  bool get hasSession => false;

  @override
  Future<String?> signIn(String email, String password) async {
    await _wait(900);
    if (_accounts[_norm(email)] != password) return 'err_credentials';
    _current = _norm(email);
    return null;
  }

  @override
  Future<String?> signUp({required String name, required String email, required String password}) async {
    await _wait(1100);
    final key = _norm(email);
    if (_accounts.containsKey(key)) return 'err_email_taken';
    _accounts[key] = password;
    _current = key;
    return null;
  }

  @override
  Future<String?> signInWithProvider(SocialProvider provider) async {
    await _wait(900);
    return null;
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait(900);

  @override
  Future<String?> verifyResetCode(String email, String code) async {
    await _wait(700);
    return RegExp(r'^\d{6}$').hasMatch(code) ? null : 'err_code';
  }

  @override
  Future<String?> updatePassword(String email, String password) async {
    await _wait(900);
    _accounts[_norm(email)] = password;
    return null;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {
    await _wait(900);
    _accounts.remove(_current);
    _current = null;
  }

  @override
  Future<ResidentSnapshot> loadResident() async {
    final now = DateTime.now();
    final charges = MockData.charges(now);
    return ResidentSnapshot(
      user: MockData.user(),
      lease: MockData.lease(),
      charges: charges,
      payments: MockData.payments(charges),
      tickets: MockData.tickets(now),
      notices: MockData.notices(now),
      stays: const [],
    );
  }

  @override
  Future<List<Property>> listings() async => MockData.properties;

  @override
  Future<List<AgencyBlock>> takenNights(List<String> propertyIds) async =>
      MockData.agencyBlocks(DateTime.now()).where((b) => propertyIds.contains(b.propertyId)).toList();

  @override
  Future<StayBooking> bookStay(
    Property p, {
    required DateTime checkIn,
    required int nights,
    required PaymentMethod method,
  }) async {
    await _wait(800);
    return StayBooking(
      id: 's${_rnd.nextInt(1 << 30)}',
      property: p,
      checkIn: DateTime(checkIn.year, checkIn.month, checkIn.day, 14),
      nights: nights,
      total: p.quote(nights).total,
      method: method,
      reference: _ref('CS'),
    );
  }

  @override
  Future<CheckoutSession> startPayment({
    required PaymentKind kind,
    required PaymentMethod method,
    List<String> chargeIds = const [],
    String? stayId,
    String? leaseRequestId,
  }) async {
    await _wait(600);
    return CheckoutSession(reference: _ref('CH'), amount: 0);
  }

  @override
  Future<PaymentOutcome> paymentStatus(String reference) async {
    await _wait(1800);
    return PaymentOutcome.paid;
  }

  @override
  Future<int> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    required String location,
    required List<String> photoPaths,
    required String propertyId,
  }) async {
    await _wait(900);
    return ++_ticketNumber;
  }

  @override
  Future<void> sendTicketMessage(String ticketId, String body) async {}

  @override
  Future<void> requestLease(Property p, {required DateTime moveIn, required int months}) => _wait(900);

  @override
  Future<LeaseHold> bookLease(Property p, {required DateTime moveIn, required int months}) async {
    await _wait(700);
    if (!p.availabilityKnown || moveIn.isBefore(DateTime(p.availableFrom.year, p.availableFrom.month, p.availableFrom.day))) {
      throw BackendException('err_unit_taken');
    }
    return LeaseHold(id: 'lr${_rnd.nextInt(1 << 30)}', amount: p.bookingAmount);
  }

  @override
  Future<void> registerDevice({required String platform, String? pushToken, required String locale}) async {}
}
