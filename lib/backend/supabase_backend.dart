import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import 'backend.dart';
import 'config.dart';

/// The real backend: the Charta Home Supabase project (auth, row level
/// security, RPCs from backend/supabase/migrations) plus the web app's
/// /api/mobile routes for what needs a server secret: PayUnit, Resend and
/// signed photo URLs. Same project and same rules as the web dashboard.
class SupabaseBackend implements ChartaBackend {
  SupabaseClient get _db => Supabase.instance.client;
  GoTrueClient get _auth => _db.auth;

  @override
  bool get isDemo => false;

  @override
  Future<void> init() async {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  // ---- auth --------------------------------------------------------------

  @override
  bool get hasSession => _auth.currentSession != null;

  @override
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
      await _db.rpc('claim_resident_profile');
      return null;
    } on AuthException catch (e) {
      return _authError(e);
    } on SocketException {
      return 'err_network';
    }
  }

  @override
  Future<String?> signUp({required String name, required String email, required String password}) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: BackendConfig.authRedirect,
        // Read by claim_resident_profile to find the agency's resident row.
        data: {'full_name': name.trim(), 'source': 'mobile'},
      );
      // With email confirmation on, Supabase returns a user with no identities
      // for an address that is already registered.
      if (res.user != null && (res.user!.identities?.isEmpty ?? false)) return 'err_email_taken';
      if (res.session == null) return 'confirm_email_sent';
      await _db.rpc('claim_resident_profile');
      return null;
    } on AuthException catch (e) {
      return _authError(e);
    } on SocketException {
      return 'err_network';
    }
  }

  @override
  Future<String?> signInWithProvider(SocialProvider provider) async {
    try {
      final ok = await _auth.signInWithOAuth(
        provider == SocialProvider.google ? OAuthProvider.google : OAuthProvider.apple,
        redirectTo: BackendConfig.authRedirect,
      );
      return ok ? null : 'err_social';
    } on AuthException catch (e) {
      return _authError(e);
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // The recovery email (sent by Supabase through Resend SMTP) must contain
    // {{ .Token }}: see backend/README.md. Errors are swallowed on purpose so
    // the screen never reveals whether an account exists.
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } catch (_) {}
  }

  @override
  Future<String?> verifyResetCode(String email, String code) async {
    try {
      await _auth.verifyOTP(type: OtpType.recovery, email: email.trim(), token: code);
      return null;
    } on AuthException {
      return 'err_code';
    }
  }

  @override
  Future<String?> updatePassword(String email, String password) async {
    try {
      await _auth.updateUser(UserAttributes(password: password));
      // A reset leaves a recovery session open; close it so the resident
      // signs in again with the new password, as on the web.
      await _auth.signOut();
      return null;
    } on AuthException catch (e) {
      return _authError(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final r = await http.delete(_api('/api/mobile/account'), headers: _headers);
    if (r.statusCode >= 400) {
      final decoded = r.body.isEmpty ? null : jsonDecode(r.body);
      throw BackendException((decoded is Map ? decoded['error_key'] as String? : null) ?? 'err_generic', r.body);
    }
    // The user no longer exists; drop the local session without asking the server.
    await _auth.signOut(scope: SignOutScope.local).catchError((_) {});
  }

  String _authError(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) return 'err_credentials';
    if (m.contains('already registered') || m.contains('already exists')) return 'err_email_taken';
    if (m.contains('not confirmed')) return 'err_email_unconfirmed';
    if (m.contains('rate limit') || e.statusCode == '429') return 'err_rate_limited';
    return 'err_generic';
  }

  // ---- web API -----------------------------------------------------------

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_auth.currentSession != null) 'Authorization': 'Bearer ${_auth.currentSession!.accessToken}',
  };

  Uri _api(String path) => Uri.parse('${BackendConfig.apiBaseUrl}$path');

  Future<dynamic> _get(String path) async {
    final r = await http.get(_api(path), headers: _headers);
    if (r.statusCode >= 400) throw BackendException('err_generic', r.body);
    return jsonDecode(r.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final r = await http.post(_api(path), headers: _headers, body: jsonEncode(body));
    final decoded = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw BackendException((decoded is Map ? decoded['error_key'] as String? : null) ?? 'err_generic', r.body);
    }
    return decoded;
  }

  // ---- data --------------------------------------------------------------

  @override
  Future<List<Property>> listings() async {
    final rows = await _get('/api/mobile/listings') as List;
    return rows.map((r) => _property(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<ResidentSnapshot> loadResident() async {
    final j = await _get('/api/mobile/me') as Map<String, dynamic>;
    final u = j['user'] as Map<String, dynamic>;
    final leaseJson = j['lease'] as Map<String, dynamic>?;
    final lease = leaseJson == null ? null : _lease(leaseJson);
    return ResidentSnapshot(
      user: UserProfile(
        name: u['name'] as String? ?? '',
        phone: u['phone'] as String? ?? '',
        email: u['email'] as String? ?? '',
        photo: u['photo'] as String? ?? '',
      ),
      lease: lease,
      charges: [for (final c in j['charges'] as List) _charge(c)],
      payments: [for (final p in j['payments'] as List) _payment(p)],
      tickets: [for (final t in j['tickets'] as List) _ticket(t)],
      notices: [for (final n in j['notices'] as List) _notice(n)],
      stays: [for (final s in j['stays'] as List) _stay(s)],
    );
  }

  @override
  Future<List<AgencyBlock>> takenNights(List<String> propertyIds) async {
    final rows = await _db.rpc('listing_taken_nights', params: {'apartment_ids': propertyIds}) as List;
    return [
      for (final r in rows)
        // check_out is the morning the guest leaves, so the last taken
        // night is the day before.
        AgencyBlock(
          propertyId: r['apartment_id'] as String,
          from: DateTime.parse(r['check_in'] as String),
          to: DateTime.parse(r['check_out'] as String).subtract(const Duration(days: 1)),
        ),
    ];
  }

  // ---- actions -----------------------------------------------------------

  @override
  Future<StayBooking> bookStay(
    Property p, {
    required DateTime checkIn,
    required int nights,
    required PaymentMethod method,
  }) async {
    final checkOut = checkIn.add(Duration(days: nights));
    try {
      final r =
          await _db.rpc(
                'book_stay',
                params: {'target_apartment': p.id, 'check_in_in': _date(checkIn), 'check_out_in': _date(checkOut)},
              )
              as Map<String, dynamic>;
      return StayBooking(
        id: r['stay_id'] as String,
        property: p,
        checkIn: DateTime(checkIn.year, checkIn.month, checkIn.day, 14),
        nights: nights,
        // The server prices the stay from stay_rates; the app's quote is
        // only a preview.
        total: (r['amount'] as num).toInt(),
        method: method,
        reference: r['reference'] as String? ?? '',
      );
    } on PostgrestException catch (e) {
      // 23P01: exclusion_violation, raised by the clash check.
      if (e.code == '23P01') {
        final night = DateTime.tryParse(e.details?.toString() ?? '') ?? checkIn;
        throw StayClash(night);
      }
      rethrow;
    }
  }

  @override
  Future<CheckoutSession> startPayment({
    required PaymentKind kind,
    required PaymentMethod method,
    List<String> chargeIds = const [],
    String? stayId,
    String? leaseRequestId,
  }) async {
    final r =
        await _post('/api/mobile/payments', {
              'kind': kind.name,
              'method': method == PaymentMethod.card ? 'card' : 'mobile_money',
              'charge_ids': chargeIds,
              'stay_id': stayId,
              'lease_request_id': leaseRequestId,
              'return_url': BackendConfig.paymentReturn,
            })
            as Map<String, dynamic>;
    return CheckoutSession(
      reference: r['reference'] as String,
      amount: (r['amount'] as num).toInt(),
      checkoutUrl: Uri.parse(r['checkout_url'] as String),
    );
  }

  @override
  Future<PaymentOutcome> paymentStatus(String reference) async {
    final r = await _get('/api/mobile/payments/$reference') as Map<String, dynamic>;
    return switch (r['status']) {
      'paid' => PaymentOutcome.paid,
      'failed' => PaymentOutcome.failed,
      'cancelled' => PaymentOutcome.cancelled,
      _ => PaymentOutcome.pending,
    };
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
    // Photos go to the private ticket-photos bucket under the user's folder.
    final uploaded = <String>[];
    final uid = _auth.currentUser!.id;
    for (final local in photoPaths.where((p) => !p.startsWith('assets/'))) {
      final name = '$uid/${DateTime.now().millisecondsSinceEpoch}-${uploaded.length}.jpg';
      await _db.storage.from('ticket-photos').upload(name, File(local));
      uploaded.add(name);
    }
    final r =
        await _db.rpc(
              'resident_create_ticket',
              params: {
                'title_in': title,
                'description_in': description,
                'category_in': category.name,
                'priority_in': priority.name,
                'location_in': location,
                'photo_paths_in': uploaded,
                'apartment_in': propertyId,
              },
            )
            as Map<String, dynamic>;
    return (r['number'] as num).toInt();
  }

  @override
  Future<void> sendTicketMessage(String ticketId, String body) =>
      _db.rpc('resident_ticket_message', params: {'ticket_in': ticketId, 'body_in': body});

  @override
  Future<LeaseHold> bookLease(Property p, {required DateTime moveIn, required int months}) async {
    try {
      final r =
          await _db.rpc(
                'book_lease',
                params: {'target_apartment': p.id, 'move_in_in': _date(moveIn), 'months_in': months},
              )
              as Map<String, dynamic>;
      return LeaseHold(id: r['request_id'] as String, amount: (r['amount'] as num).toInt());
    } on PostgrestException catch (e) {
      // 23P01: someone holds or rents those months; details = first free day.
      if (e.code == '23P01') throw BackendException('err_unit_taken', e.details?.toString());
      if (e.details?.toString() == 'occupied') throw BackendException('err_unit_taken');
      rethrow;
    }
  }

  @override
  Future<void> requestLease(Property p, {required DateTime moveIn, required int months}) =>
      _db.rpc('request_lease', params: {'target_apartment': p.id, 'move_in_in': _date(moveIn), 'months_in': months});

  @override
  Future<void> registerDevice({required String platform, String? pushToken, required String locale}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.from('resident_devices').upsert({
      'user_id': user.id,
      'platform': platform,
      'push_token': pushToken,
      'locale': locale,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,platform');
  }

  // ---- json → models -------------------------------------------------------

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _d(Object? v) => DateTime.parse(v as String).toLocal();
  static DateTime? _dn(Object? v) => v == null ? null : _d(v);
  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere((e) => e.name == name, orElse: () => fallback);

  static Property _property(Map<String, dynamic> j) {
    final agent = j['agent'] as Map<String, dynamic>? ?? const {};
    final rates = (j['stay_rates'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
    );
    return Property(
      id: j['id'] as String,
      title: j['title'] as String,
      building: j['building'] as String? ?? '',
      neighborhood: j['neighborhood'] as String? ?? '',
      city: j['city'] as String? ?? '',
      kind: _enum(PropertyKind.values, j['kind'], PropertyKind.apartment),
      // A home published without photos still needs a cover to show.
      photos: [
        for (final p in j['photos'] as List? ?? const [])
          if ((p as String?)?.isNotEmpty ?? false) p as String,
      ].ifEmpty(const ['assets/hero-door.png']),
      rent: _i(j['rent']),
      cycle: _enum(LeaseCycle.values, j['cycle'], LeaseCycle.monthly),
      deposit: _i(j['deposit']),
      rooms: _i(j['rooms']),
      bathrooms: _i(j['bathrooms']),
      sqm: _i(j['sqm']),
      floor: j['floor'] as String? ?? '',
      amenities: [for (final a in j['amenities'] as List? ?? const []) a as String],
      description: j['description'] as String? ?? '',
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      reviews: _i(j['reviews']),
      agency: j['agency'] as String? ?? '',
      agent: Agent(
        name: agent['name'] as String? ?? '',
        photo: agent['photo'] as String?,
        phone: agent['phone'] as String? ?? '',
        rating: (agent['rating'] as num?)?.toDouble() ?? 0,
        reviews: _i(agent['reviews']),
      ),
      // Null means occupied by a lease with no end date yet.
      availableFrom: _dn(j['available_from']) ?? DateTime.now(),
      // `availability` (now | on_date | on_notice) says it outright; older
      // servers only had the date, null meaning occupied with no end date.
      availabilityKnown: j['availability'] != null
          ? j['availability'] != 'on_notice'
          : (j.containsKey('available_from') ? j['available_from'] != null : true),
      occupied: j['occupied'] as bool? ?? false,
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      isVerified: j['verified'] as bool? ?? true,
      isNew: j['is_new'] as bool? ?? false,
      stayRates: rates,
    );
  }

  static Lease _lease(Map<String, dynamic> j) => Lease(
    id: j['id'] as String,
    property: _property(j['property'] as Map<String, dynamic>),
    unitLabel: j['unit'] as String? ?? '',
    startsOn: _d(j['starts_on']),
    endsOn: _dn(j['ends_on']),
    rent: _i(j['rent']),
    cycle: _enum(LeaseCycle.values, j['cycle'], LeaseCycle.monthly),
    dueDay: _i(j['due_day']),
    deposit: _i(j['deposit']),
    currency: j['currency'] as String? ?? 'XAF',
  );

  static RentCharge _charge(dynamic j) => RentCharge(
    id: j['id'] as String,
    periodStart: _d(j['period_start']),
    periodEnd: _d(j['period_end']),
    dueOn: _d(j['due_on']),
    amount: _i(j['amount']),
    paid: _i(j['paid']),
  );

  static Payment _payment(dynamic j) => Payment(
    id: j['id'] as String,
    amount: _i(j['amount']),
    paidOn: _d(j['paid_on']),
    method: switch (j['method']) {
      'mtn_momo' => PaymentMethod.mtnMomo,
      'orange_money' => PaymentMethod.orangeMoney,
      'card' => PaymentMethod.card,
      'bank_transfer' => PaymentMethod.bankTransfer,
      'cash' => PaymentMethod.cash,
      _ => PaymentMethod.mobileMoney,
    },
    reference: j['reference'] as String? ?? '',
    periods: [for (final d in j['periods'] as List? ?? const []) _d(d)],
  );

  static Ticket _ticket(dynamic j) {
    final tech = j['technician'] as Map<String, dynamic>?;
    return Ticket(
      id: j['id'] as String,
      number: _i(j['number']),
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      category: _enum(TicketCategory.values, j['category'], TicketCategory.other),
      priority: _enum(TicketPriority.values, j['priority'], TicketPriority.normal),
      status: switch (j['status']) {
        'assigned' => TicketStatus.assigned,
        'in_progress' => TicketStatus.inProgress,
        'resolved' => TicketStatus.resolved,
        'cancelled' => TicketStatus.cancelled,
        _ => TicketStatus.newTicket,
      },
      openedAt: _d(j['opened_at']),
      location: j['location'] as String? ?? '',
      technician: tech == null
          ? null
          : Technician(
              name: tech['name'] as String? ?? '',
              trade: tech['trade'] as String? ?? '',
              phone: tech['phone'] as String? ?? '',
            ),
      visitAt: _dn(j['visit_at']),
      resolvedAt: _dn(j['resolved_at']),
      rating: (j['rating'] as num?)?.toInt(),
      photos: [for (final p in j['photos'] as List? ?? const []) p as String],
      messages: [
        for (final m in j['messages'] as List? ?? const [])
          TicketMessage(
            fromMe: m['from_me'] as bool? ?? false,
            body: m['body'] as String? ?? '',
            at: _d(m['at']),
            author: m['author'] as String?,
          ),
      ],
    );
  }

  static Notice _notice(dynamic j) => Notice(
    kind: _enum(NoticeKind.values, j['kind'], NoticeKind.agency),
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    at: _d(j['at']),
    read: j['read'] as bool? ?? false,
  );

  static StayBooking _stay(dynamic j) => StayBooking(
    id: j['id'] as String,
    property: _property(j['property'] as Map<String, dynamic>),
    checkIn: _d(j['check_in']),
    nights: _i(j['nights']),
    total: _i(j['total']),
    method: j['method'] == 'card' ? PaymentMethod.card : PaymentMethod.mobileMoney,
    reference: j['reference'] as String? ?? '',
  );
}

extension on List<String> {
  List<String> ifEmpty(List<String> fallback) => isEmpty ? fallback : this;
}
