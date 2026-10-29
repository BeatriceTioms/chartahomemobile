// Tenant-side view of the Charta Home data model.
//
// These mirror the SaaS tables (supabase/migrations) from the resident's
// point of view: a listing is an apartment with no active lease, a lease owns
// rent charges, payments are allocated to charges, and tickets carry a
// message thread and an optional technician.

enum LeaseCycle { daily, monthly, quarterly, semester, yearly }

enum ChargeState { paid, pending, overdue }

enum PaymentMethod { mobileMoney, mtnMomo, orangeMoney, card, bankTransfer, cash }

enum TicketStatus { newTicket, assigned, inProgress, resolved, cancelled }

enum TicketPriority { normal, high, urgent }

enum TicketCategory { plumbing, electrical, appliance, locks, pests, painting, cleaning, other }

enum PropertyKind { apartment, studio, house, villa, duplex }

enum VisitStatus { requested, confirmed, done, cancelled }

enum ApplicationStatus { submitted, reserved, reviewing, approved, declined }

class Agent {
  const Agent({required this.name, this.photo, required this.phone, required this.rating, required this.reviews});
  final String name;
  final String? photo;
  final String phone;
  final double rating;
  final int reviews;
}

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.building,
    required this.neighborhood,
    required this.city,
    required this.kind,
    required this.photos,
    required this.rent,
    required this.cycle,
    required this.deposit,
    required this.rooms,
    required this.bathrooms,
    required this.sqm,
    required this.floor,
    required this.amenities,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.agency,
    required this.agent,
    required this.availableFrom,
    required this.lat,
    required this.lng,
    this.isVerified = true,
    this.isNew = false,
    this.matchScore,
    this.stayRates = const {},
    this.occupied = false,
    this.availabilityKnown = true,
  });

  final String id;
  final String title;
  final String building;
  final String neighborhood;
  final String city;
  final PropertyKind kind;
  final List<String> photos;
  final int rent;
  final LeaseCycle cycle;
  final int deposit;
  final int rooms;
  final int bathrooms;
  final int sqm;
  final String floor;
  final List<String> amenities;
  final String description;
  final double rating;
  final int reviews;
  final String agency;
  final Agent agent;
  final DateTime availableFrom;

  /// A tenant lives there today. It can still be booked from [availableFrom],
  /// the day after the lease ends.
  final bool occupied;

  /// False when the current lease has no end date: the agency has to say when
  /// the home frees up, so it can be asked for but not booked and paid.
  final bool availabilityKnown;

  bool get availableNow {
    final now = DateTime.now();
    return availabilityKnown && !availableFrom.isAfter(DateTime(now.year, now.month, now.day));
  }

  /// Paid to book a monthly rental: the first month and the deposit.
  int get bookingAmount => rent + deposit;

  /// Building location, for the map on the listing page.
  final double lat;
  final double lng;
  final bool isVerified;
  final bool isNew;
  final int? matchScore;

  /// The agency's short-stay packages, as on the web (`stay_rates`):
  /// number of nights → price for that many nights. Empty means the home is
  /// let monthly only.
  final Map<int, int> stayRates;

  bool get shortStay => stayRates.isNotEmpty;

  List<int> get packageNights => stayRates.keys.toList()..sort();

  /// Price of one night: the 1-night package, or the shortest package
  /// spread over its nights.
  int? get nightlyRate {
    if (!shortStay) return null;
    final first = packageNights.first;
    return (stayRates[first]! / first).round();
  }

  /// Price for any number of nights. The longest package that fits sets the
  /// per-night price (an exact package is used as is), so longer stays cost
  /// less per night exactly as the agency priced them.
  StayQuote quote(int nights) {
    final base = (nightlyRate ?? 0) * nights;
    final fitting = packageNights.where((k) => k <= nights).toList();
    if (fitting.isEmpty) {
      return StayQuote(nights: nights, subtotal: base, total: base, packageNights: null);
    }
    final k = fitting.last;
    final total = k == nights ? stayRates[k]! : (stayRates[k]! / k * nights).round();
    return StayQuote(nights: nights, subtotal: base, total: total > base ? base : total, packageNights: k);
  }

  String get cover => photos.first;
  String get address => '$neighborhood, $city';
}

class Lease {
  const Lease({
    required this.id,
    required this.property,
    required this.unitLabel,
    required this.startsOn,
    required this.endsOn,
    required this.rent,
    required this.cycle,
    required this.dueDay,
    required this.deposit,
    required this.currency,
  });

  final String id;
  final Property property;
  final String unitLabel;
  final DateTime startsOn;
  final DateTime? endsOn;
  final int rent;
  final LeaseCycle cycle;
  final int dueDay;
  final int deposit;
  final String currency;
}

class RentCharge {
  RentCharge({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.dueOn,
    required this.amount,
    this.paid = 0,
  });

  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueOn;
  final int amount;
  int paid;

  int get balance => amount - paid;

  ChargeState stateOn(DateTime today) {
    if (paid >= amount) return ChargeState.paid;
    final day = DateTime(today.year, today.month, today.day);
    return dueOn.isBefore(day) ? ChargeState.overdue : ChargeState.pending;
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.paidOn,
    required this.method,
    required this.reference,
    required this.periods,
  });

  final String id;
  final int amount;
  final DateTime paidOn;
  final PaymentMethod method;
  final String reference;

  /// Human label of the rent periods this payment settled.
  final List<DateTime> periods;
}

class Technician {
  const Technician({required this.name, required this.trade, required this.phone, this.photo});
  final String name;
  final String trade;
  final String phone;
  final String? photo;
}

class TicketMessage {
  const TicketMessage({required this.fromMe, required this.body, required this.at, this.author});
  final bool fromMe;
  final String body;
  final DateTime at;
  final String? author;
}

class Ticket {
  Ticket({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.openedAt,
    required this.location,
    this.technician,
    this.visitAt,
    this.resolvedAt,
    this.rating,
    List<String>? photos,
    List<TicketMessage>? messages,
  }) : photos = photos ?? [],
       messages = messages ?? [];

  final String id;
  final int number;
  final String title;
  final String description;
  final TicketCategory category;
  TicketPriority priority;
  TicketStatus status;
  final DateTime openedAt;
  final String location;
  Technician? technician;
  DateTime? visitAt;
  DateTime? resolvedAt;
  int? rating;
  final List<String> photos;
  final List<TicketMessage> messages;

  bool get isOpen => status != TicketStatus.resolved && status != TicketStatus.cancelled;
}

class Visit {
  Visit({required this.id, required this.property, required this.at, this.status = VisitStatus.requested});
  final String id;
  final Property property;
  final DateTime at;
  VisitStatus status;
}

class RentalApplication {
  RentalApplication({
    required this.id,
    required this.property,
    required this.moveIn,
    required this.months,
    required this.occupants,
    required this.submittedAt,
    this.status = ApplicationStatus.submitted,
  });
  final String id;
  final Property property;
  final DateTime moveIn;
  final int months;
  final int occupants;
  final DateTime submittedAt;
  ApplicationStatus status;
}

/// A monthly rental held while it is paid (server `lease_requests`).
class LeaseHold {
  const LeaseHold({required this.id, required this.amount});
  final String id;
  final int amount;
}

enum NoticeKind { rent, maintenance, visit, application, agency }

class Notice {
  Notice({required this.kind, required this.title, required this.body, required this.at, this.read = false});
  final NoticeKind kind;
  final String title;
  final String body;
  final DateTime at;
  bool read;
}

class UserProfile {
  UserProfile({required this.name, required this.phone, required this.email, required this.photo});
  String name;
  String phone;
  String email;
  String photo;

  String get firstName => name.split(' ').first;
}

/// A short stay booked and paid up front through PayUnit.
class StayBooking {
  const StayBooking({
    required this.id,
    required this.property,
    required this.checkIn,
    required this.nights,
    required this.total,
    required this.method,
    required this.reference,
  });

  final String id;
  final Property property;
  final DateTime checkIn;
  final int nights;
  final int total;
  final PaymentMethod method;
  final String reference;

  DateTime get checkOut => checkIn.add(Duration(days: nights));
}

class StayQuote {
  const StayQuote({required this.nights, required this.subtotal, required this.total, required this.packageNights});
  final int nights;

  /// Nights × the 1-night price, before any package.
  final int subtotal;
  final int total;

  /// The package whose per-night price applies, if any.
  final int? packageNights;

  int get discount => subtotal - total;
  int get percent => subtotal == 0 ? 0 : (discount * 100 / subtotal).round();
}

/// Nights the agency has closed on its calendar (owner use, maintenance,
/// another booking taken at the desk). [from] is the first blocked night and
/// [to] the last, both inclusive.
class AgencyBlock {
  const AgencyBlock({required this.propertyId, required this.from, required this.to});
  final String propertyId;
  final DateTime from;
  final DateTime to;

  bool covers(DateTime night) => !night.isBefore(from) && !night.isAfter(to);
}
