import 'package:charta_home/data/mock_data.dart';
import 'package:charta_home/data/models.dart';
import 'package:charta_home/state/app_state.dart';
import 'package:charta_home/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:charta_home/backend/backend.dart';

void main() {
  test('money uses FCFA with space grouping', () {
    expect(money(350000, 'XAF'), '350 000 FCFA');
    expect(money(1500000, 'XAF', compact: true), '1.5M FCFA');
  });

  test('paying settles the selected charges and records a payment', () async {
    final app = AppState(lang: 'en');
    final due = app.dueCharges;
    expect(due, isNotEmpty);
    final before = app.payments.length;
    final p = await app.pay(due, PaymentMethod.mobileMoney);
    expect(p.amount, due.fold<int>(0, (s, c) => s + c.amount));
    expect(app.balanceDue, 0);
    expect(app.payments.length, before + 1);
  });

  test('creating a ticket numbers it after the last one', () async {
    final app = AppState(lang: 'en');
    final t = await app.createTicket(
      title: 'Door',
      description: 'The lock is stuck',
      category: TicketCategory.locks,
      priority: TicketPriority.normal,
      location: 'Entrance',
      photos: const [],
      home: MockData.lease().property,
    );
    expect(t.number, 1043);
    expect(app.openTickets.first, t);
  });

  test('rent can be paid up to six months ahead', () async {
    final app = AppState(lang: 'en');
    final payable = app.payableCharges();
    final last = payable.last.periodStart;
    final limit = DateTime(app.today.year, app.today.month + 6);
    expect(last.year * 12 + last.month, limit.year * 12 + limit.month);
    await app.pay(payable, PaymentMethod.mobileMoney);
    expect(app.unpaidCharges, isEmpty);
    expect(app.payableCharges(), isEmpty);
  });

  test('a short stay is priced per night and listed as upcoming', () async {
    final app = AppState(lang: 'en');
    final p = app.properties.firstWhere((p) => p.shortStay);
    final start = app.nextFreeCheckIn(p, nights: 3)!;
    final b = await app.bookStay(
      p,
      checkIn: start,
      nights: 3,
      method: PaymentMethod.mobileMoney,
    );
    expect(b.total, p.quote(3).total);
    expect(b.checkOut.difference(b.checkIn).inDays, 3);
    expect(app.upcomingStays, contains(b));
  });

  test(
    'agency-blocked nights cannot be booked and stays never overlap',
    () async {
      final app = AppState(lang: 'en');
      final p = app.properties.firstWhere((p) => p.id == 'p1');
      final block = app.agencyBlocks.firstWhere((b) => b.propertyId == 'p1');
      expect(app.isNightFree(p, block.from), isFalse);
      final dayBefore = block.from.subtract(const Duration(days: 1));
      // One night fits before the block; two would run into it.
      expect(app.firstUnavailableNight(p, dayBefore, 1), isNull);
      expect(app.firstUnavailableNight(p, dayBefore, 2), block.from);
      expect(
        () => app.bookStay(
          p,
          checkIn: dayBefore,
          nights: 2,
          method: PaymentMethod.card,
        ),
        throwsA(isA<StayUnavailable>()),
      );
      final b = await app.bookStay(
        p,
        checkIn: dayBefore,
        nights: 1,
        method: PaymentMethod.card,
      );
      expect(app.isNightFree(p, b.checkIn), isFalse);
    },
  );

  test('stay price follows the agency packages', () {
    final p = AppState(lang: 'en').properties.firstWhere((p) => p.id == 'p1');
    expect(p.quote(1).total, p.stayRates[1]);
    expect(p.quote(3).total, p.stayRates[3]);
    expect(p.quote(2).total, p.nightlyRate! * 2);
    // 10 nights use the 7-night package's per-night price.
    expect(p.quote(10).total, (p.stayRates[7]! / 7 * 10).round());
    expect(p.quote(10).packageNights, 7);
    expect(p.quote(10).discount, greaterThan(0));
  });

  test('sign in, sign up and password reset', () async {
    final app = AppState(lang: 'en');
    expect(
      await app.signIn('arnaud.fouda@mail.cm', 'wrong-pass1'),
      'err_credentials',
    );
    expect(
      await app.signUp(
        name: 'Ada',
        email: 'arnaud.fouda@mail.cm',
        password: 'abcd1234',
      ),
      'err_email_taken',
    );
    expect(
      await app.signUp(
        name: 'Ada N',
        email: 'ada@mail.cm',
        password: 'abcd1234',
      ),
      isNull,
    );
    expect(app.signedIn, isTrue);
    app.signOut();
    expect(await app.verifyResetCode('ada@mail.cm', '12a'), 'err_code');
    await app.updatePassword('ada@mail.cm', 'newpass99');
    expect(await app.signIn('Ada@Mail.cm ', 'newpass99'), isNull);
  });

  test('deleting the account signs out and the login stops working', () async {
    final app = AppState(lang: 'en');
    expect(
      await app.signUp(
        name: 'Ada N',
        email: 'ada@mail.cm',
        password: 'abcd1234',
      ),
      isNull,
    );
    await app.deleteAccount();
    expect(app.signedIn, isFalse);
    expect(await app.signIn('ada@mail.cm', 'abcd1234'), 'err_credentials');
  });

  test(
    'a vacant home can be booked and paid; an occupied one only from its free day',
    () async {
      final app = AppState(lang: 'en');
      final vacant = MockData.properties.firstWhere((p) => p.availableNow);
      final occupied = MockData.properties.firstWhere((p) => p.occupied);
      expect(occupied.availableNow, isFalse);
      expect(
        app.canMoveIn(
          occupied,
          occupied.availableFrom.subtract(const Duration(days: 1)),
        ),
        isFalse,
      );

      final hold = await app.bookLease(
        vacant,
        moveIn: DateTime.now(),
        months: 12,
        method: PaymentMethod.mobileMoney,
      );
      expect(hold.amount, vacant.rent + vacant.deposit);
      expect(app.applications.first.status, ApplicationStatus.reserved);

      await expectLater(
        app.bookLease(
          occupied,
          moveIn: DateTime.now(),
          months: 6,
          method: PaymentMethod.card,
        ),
        throwsA(isA<BackendException>()),
      );
    },
  );
}
