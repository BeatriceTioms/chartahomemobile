import 'models.dart';

/// Demo content so every screen can be explored before the app is wired to
/// the Charta Home Supabase backend. Replace `MockData` with a repository that
/// reads the same shapes from the API; nothing in the UI depends on it being
/// static.
class MockData {
  MockData._();

  static const _p = 'assets/photos';

  static const agents = [
    Agent(name: 'Aïcha Mbarga', photo: '$_p/people-1.jpg', phone: '+237677001122', rating: 4.9, reviews: 128),
    Agent(name: 'Serge Nkoulou', photo: '$_p/people-2.jpg', phone: '+237699334455', rating: 4.7, reviews: 86),
    Agent(name: 'Brenda Tchoupo', phone: '+237655778899', rating: 4.8, reviews: 64),
  ];

  static final properties = <Property>[
    Property(
      id: 'p1',
      title: 'Bastos Garden Residence',
      building: 'Résidence Les Palmiers',
      neighborhood: 'Bastos',
      city: 'Yaoundé',
      kind: PropertyKind.apartment,
      photos: const ['$_p/building-1.jpg', '$_p/interior-1.jpg', '$_p/interior-2.jpg', '$_p/interior-3.jpg'],
      rent: 350000,
      cycle: LeaseCycle.monthly,
      deposit: 700000,
      rooms: 3,
      bathrooms: 2,
      sqm: 120,
      floor: '2',
      amenities: const ['wifi', 'parking', 'security', 'generator', 'water', 'ac'],
      description:
          'A bright three-bedroom apartment on a quiet, tree-lined street in Bastos. Large living room opening onto a balcony, fitted kitchen, 24/7 guard and a backup generator for the whole building.',
      rating: 4.9,
      reviews: 42,
      agency: 'Charta Immobilier',
      agent: agents[0],
      availableFrom: DateTime(2026, 10, 1),
      lat: 3.8962,
      lng: 11.5128,
      stayRates: const {1: 35000, 3: 99000, 7: 220000, 28: 784000},
      matchScore: 98,
      isNew: true,
    ),
    Property(
      id: 'p2',
      title: 'Bonapriso Skyline Loft',
      building: 'Immeuble Horizon',
      neighborhood: 'Bonapriso',
      city: 'Douala',
      kind: PropertyKind.duplex,
      photos: const ['$_p/building-2.jpg', '$_p/interior-2.jpg', '$_p/interior-4.jpg'],
      rent: 480000,
      cycle: LeaseCycle.monthly,
      deposit: 960000,
      rooms: 4,
      bathrooms: 3,
      sqm: 165,
      floor: '6',
      amenities: const ['wifi', 'parking', 'security', 'gym', 'pool', 'ac', 'elevator'],
      description:
          'Duplex on the top floors of a new tower, with a terrace looking over the Wouri. Lift, pool and gym on site, two parking spaces included.',
      rating: 4.8,
      reviews: 31,
      agency: 'Horizon Properties',
      agent: agents[1],
      availableFrom: DateTime(2026, 11, 1),
      occupied: true,
      lat: 4.0268,
      lng: 9.6934,
      stayRates: const {1: 45000, 3: 129000, 7: 283500, 28: 945000},
      matchScore: 95,
    ),
    Property(
      id: 'p3',
      title: 'Santa Barbara Studio',
      building: 'Villa Santa Barbara',
      neighborhood: 'Santa Barbara',
      city: 'Yaoundé',
      kind: PropertyKind.studio,
      photos: const ['$_p/building-3.jpg', '$_p/interior-3.jpg', '$_p/interior-1.jpg'],
      rent: 120000,
      cycle: LeaseCycle.monthly,
      deposit: 240000,
      rooms: 1,
      bathrooms: 1,
      sqm: 38,
      floor: '1',
      amenities: const ['wifi', 'water', 'security'],
      description:
          'Furnished studio, ideal for a student or young professional. Five minutes from the main road, with water and internet included in the rent.',
      rating: 4.6,
      reviews: 18,
      agency: 'Charta Immobilier',
      agent: agents[2],
      availableFrom: DateTime(2026, 9, 28),
      lat: 3.8901,
      lng: 11.5206,
      stayRates: const {1: 15000, 7: 99750, 28: 357000},
      matchScore: 92,
    ),
    Property(
      id: 'p4',
      title: 'Akwa Family Villa',
      building: 'Villa Akwa Nord',
      neighborhood: 'Akwa Nord',
      city: 'Douala',
      kind: PropertyKind.villa,
      photos: const ['$_p/building-4.jpg', '$_p/interior-4.jpg', '$_p/interior-2.jpg'],
      rent: 750000,
      cycle: LeaseCycle.monthly,
      deposit: 1500000,
      rooms: 5,
      bathrooms: 4,
      sqm: 280,
      floor: 'G',
      amenities: const ['parking', 'security', 'generator', 'garden', 'water', 'ac'],
      description:
          'Detached family villa with a private garden and a separate staff quarter. Gated compound with a guard, borehole water and a generator.',
      rating: 4.7,
      reviews: 12,
      agency: 'Horizon Properties',
      agent: agents[1],
      availableFrom: DateTime(2026, 10, 15),
      lat: 4.0652,
      lng: 9.7158,
    ),
    Property(
      id: 'p5',
      title: 'Omnisport City View',
      building: 'Résidence Omnisport',
      neighborhood: 'Omnisport',
      city: 'Yaoundé',
      kind: PropertyKind.apartment,
      photos: const ['$_p/city.jpg', '$_p/interior-1.jpg', '$_p/interior-3.jpg'],
      rent: 220000,
      cycle: LeaseCycle.monthly,
      deposit: 440000,
      rooms: 2,
      bathrooms: 1,
      sqm: 72,
      floor: '4',
      amenities: const ['wifi', 'security', 'water', 'elevator'],
      description: 'Two-bedroom apartment with a city view, close to the stadium, schools and the market.',
      rating: 4.5,
      reviews: 27,
      agency: 'Charta Immobilier',
      agent: agents[0],
      availableFrom: DateTime(2026, 10, 1),
      lat: 3.8868,
      lng: 11.5409,
      stayRates: const {1: 20000, 3: 57000, 7: 126000, 28: 448000},
      isNew: true,
    ),
  ];

  static const technicians = [
    Technician(name: 'Jean-Paul Essomba', trade: 'Plumber', phone: '+237677445566'),
    Technician(name: 'Moussa Bello', trade: 'Electrician', phone: '+237699112233'),
  ];

  /// What the agencies' calendars say is taken, relative to today so the
  /// demo always has something to avoid.
  static List<AgencyBlock> agencyBlocks(DateTime today) {
    DateTime d(int n) => DateTime(today.year, today.month, today.day + n);
    return [
      AgencyBlock(propertyId: 'p1', from: d(4), to: d(6)),
      AgencyBlock(propertyId: 'p1', from: d(13), to: d(15)),
      AgencyBlock(propertyId: 'p2', from: d(2), to: d(3)),
      AgencyBlock(propertyId: 'p3', from: d(1), to: d(1)),
      AgencyBlock(propertyId: 'p3', from: d(9), to: d(12)),
      AgencyBlock(propertyId: 'p5', from: d(5), to: d(8)),
    ];
  }

  /// Demo account for the sign-in screen. Replace with Supabase auth.
  static const demoEmail = 'arnaud.fouda@mail.cm';
  static const demoPassword = 'Charta2026';

  static UserProfile user() => UserProfile(
    name: 'Arnaud Fouda',
    phone: '+237 677 12 34 56',
    email: 'arnaud.fouda@mail.cm',
    photo: '$_p/people-6.jpg',
  );

  /// The resident already lives in unit B2 of the first listing's building.
  static Lease lease() => Lease(
    id: 'l1',
    property: properties[0],
    unitLabel: 'B2',
    startsOn: DateTime(2025, 11, 1),
    endsOn: DateTime(2026, 10, 31),
    rent: 350000,
    cycle: LeaseCycle.monthly,
    dueDay: 5,
    deposit: 700000,
    currency: 'XAF',
  );

  static List<RentCharge> charges(DateTime today) {
    final list = <RentCharge>[];
    // Last six months: all settled except the current one.
    for (var i = 5; i >= 0; i--) {
      final start = DateTime(today.year, today.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 0);
      list.add(
        RentCharge(
          id: 'c${start.year}${start.month}',
          periodStart: start,
          periodEnd: end,
          dueOn: DateTime(start.year, start.month, 5),
          amount: 350000,
          paid: i == 0 ? 0 : 350000,
        ),
      );
    }
    // Next month is already issued so it can be paid in advance.
    final next = DateTime(today.year, today.month + 1, 1);
    list.add(
      RentCharge(
        id: 'c${next.year}${next.month}',
        periodStart: next,
        periodEnd: DateTime(next.year, next.month + 1, 0),
        dueOn: DateTime(next.year, next.month, 5),
        amount: 350000,
      ),
    );
    return list;
  }

  static List<Payment> payments(List<RentCharge> charges) {
    final methods = [
      PaymentMethod.mtnMomo,
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMomo,
      PaymentMethod.card,
      PaymentMethod.mtnMomo,
    ];
    final paid = charges.where((c) => c.paid >= c.amount).toList().reversed.toList();
    return [
      for (var i = 0; i < paid.length; i++)
        Payment(
          id: 'pay$i',
          amount: paid[i].amount,
          paidOn: paid[i].dueOn.subtract(Duration(days: i.isEven ? 2 : 0)),
          method: methods[i % methods.length],
          reference: 'CH${(482913 - i * 7331).toRadixString(16).toUpperCase()}',
          periods: [paid[i].periodStart],
        ),
    ];
  }

  static List<Ticket> tickets(DateTime now) => [
    Ticket(
      id: 't1',
      number: 1042,
      title: 'Kitchen sink is leaking',
      description: 'Water drips from the pipe under the kitchen sink whenever the tap is open.',
      category: TicketCategory.plumbing,
      priority: TicketPriority.high,
      status: TicketStatus.inProgress,
      openedAt: now.subtract(const Duration(days: 2, hours: 3)),
      location: 'Kitchen',
      technician: technicians[0],
      visitAt: DateTime(now.year, now.month, now.day + 1, 10),
      photos: const ['$_p/interior-2.jpg'],
      messages: [
        TicketMessage(
          fromMe: true,
          body: 'Water drips from the pipe under the kitchen sink whenever the tap is open.',
          at: now.subtract(const Duration(days: 2, hours: 3)),
        ),
        TicketMessage(
          fromMe: false,
          author: 'Charta Immobilier',
          body: 'Thanks Arnaud, we have assigned Jean-Paul, our plumber.',
          at: now.subtract(const Duration(days: 2, hours: 1)),
        ),
        TicketMessage(
          fromMe: false,
          author: 'Jean-Paul Essomba',
          body: 'I will come tomorrow at 10:00 with a new seal. Please keep the area under the sink clear.',
          at: now.subtract(const Duration(hours: 20)),
        ),
      ],
    ),
    Ticket(
      id: 't2',
      number: 1031,
      title: 'Bedroom socket not working',
      description: 'The socket next to the bed has no power since the storm.',
      category: TicketCategory.electrical,
      priority: TicketPriority.normal,
      status: TicketStatus.resolved,
      openedAt: now.subtract(const Duration(days: 19)),
      resolvedAt: now.subtract(const Duration(days: 17)),
      location: 'Main bedroom',
      technician: technicians[1],
      rating: 5,
      messages: [
        TicketMessage(
          fromMe: true,
          body: 'The socket next to the bed has no power since the storm.',
          at: now.subtract(const Duration(days: 19)),
        ),
        TicketMessage(
          fromMe: false,
          author: 'Moussa Bello',
          body: 'Replaced the burnt socket and checked the circuit. All good now.',
          at: now.subtract(const Duration(days: 17)),
        ),
      ],
    ),
  ];

  static List<Notice> notices(DateTime now) => [
    Notice(
      kind: NoticeKind.rent,
      title: 'rent_due_notice_title',
      body: 'rent_due_notice_body',
      at: now.subtract(const Duration(hours: 2)),
    ),
    Notice(
      kind: NoticeKind.maintenance,
      title: 'Technician visit tomorrow',
      body: 'Jean-Paul will come at 10:00 for ticket #1042.',
      at: now.subtract(const Duration(hours: 20)),
    ),
    Notice(
      kind: NoticeKind.agency,
      title: 'Water cut on Saturday',
      body: 'Résidence Les Palmiers: the tank is cleaned Saturday 08:00–12:00.',
      at: now.subtract(const Duration(days: 3)),
      read: true,
    ),
  ];
}
