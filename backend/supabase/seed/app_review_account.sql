-- ---------------------------------------------------------------------------
-- Demo data for App Store and Google Play review.
--
-- Reviewers sign in and open every tab, so the review account needs a home,
-- a lease, rent due, a payment, a repair and homes to browse. Run this once in
-- the Supabase SQL editor, then sign up in the app with review@chartahome.com:
-- the sign-up links the account to the resident row below by email.
--
-- Everything sits in its own agency, "Charta Home Démo", so it never mixes
-- with a real agency. Its two listed homes are visible in Explore to everyone;
-- unlist them once real agencies publish (see the bottom of this file).
-- Running it again does nothing if the demo agency already exists.
-- ---------------------------------------------------------------------------
do $$
declare
  ag uuid; bl uuid; home uuid; flat uuid; studio uuid; res uuid; le uuid;
  m0 date := date_trunc('month', current_date)::date;   -- this month
  c uuid; pay uuid; i int;
begin
  if exists (select 1 from agencies where name = 'Charta Home Démo') then
    raise notice 'demo agency already exists, nothing to do';
    return;
  end if;

  insert into agencies (name, country, city, currency, locale, whatsapp_number)
  values ('Charta Home Démo', 'Cameroon', 'Yaoundé', 'XAF', 'fr', '+237600000000')
  returning id into ag;

  insert into buildings (agency_id, name, address, city, neighborhood, latitude, longitude, amenities, notes)
  values (ag, 'Résidence Les Palmiers', 'Rue 1.794, Bastos', 'Yaoundé', 'Bastos', 3.893000, 11.508000,
          array['Wi-Fi', 'Parking', 'Gardiennage 24/7', 'Groupe électrogène', 'Eau courante'],
          'Résidence calme à Bastos, gardiennage jour et nuit.')
  returning id into bl;

  -- The reviewer's own home (leased, so not listed).
  insert into apartments (agency_id, building_id, label, floor, rooms, bathrooms, sqm, base_rent)
  values (ag, bl, 'A1', '1', 2, 1, 75, 250000) returning id into home;

  -- Two homes to browse: one monthly, one for short stays too.
  insert into apartments (agency_id, building_id, label, floor, rooms, bathrooms, sqm, base_rent,
                          listed, kind, listing_title, listing_description, available_from)
  values (ag, bl, 'B2', '2', 3, 2, 120, 350000, true, 'apartment', 'Appartement 3 chambres à Bastos',
          'Appartement lumineux de trois chambres avec balcon, cuisine équipée, gardiennage 24/7 et groupe électrogène.',
          current_date)
  returning id into flat;

  insert into apartments (agency_id, building_id, label, floor, rooms, bathrooms, sqm, base_rent,
                          listed, short_stay, kind, listing_title, listing_description, available_from)
  values (ag, bl, 'S1', 'RDC', 1, 1, 38, 150000, true, true, 'studio', 'Studio meublé à Bastos',
          'Studio meublé et climatisé, idéal pour un court séjour. Wi-Fi, linge et eau chaude inclus.',
          current_date)
  returning id into studio;

  insert into stay_rates (agency_id, apartment_id, nights, price) values
    (ag, studio, 1, 25000), (ag, studio, 3, 70000), (ag, studio, 7, 150000), (ag, studio, 28, 520000);

  insert into residents (agency_id, full_name, phone_e164, email)
  values (ag, 'App Review', '+237600000001', 'review@chartahome.com') returning id into res;

  insert into leases (agency_id, apartment_id, resident_id, rent_amount, deposit, due_day, starts_on, ends_on)
  values (ag, home, res, 250000, 500000, 5, (m0 - interval '3 months')::date, (m0 + interval '21 months - 1 day')::date)
  returning id into le;

  -- Three months paid, this month due.
  for i in reverse 3..0 loop
    insert into rent_charges (agency_id, lease_id, period_start, period_end, amount, due_on)
    values (ag, le, (m0 - make_interval(months => i))::date,
            (m0 - make_interval(months => i) + interval '1 month - 1 day')::date,
            250000, (m0 - make_interval(months => i) + interval '4 days')::date)
    returning id into c;
    if i > 0 then
      insert into payments (agency_id, lease_id, amount, paid_on, method, reference)
      values (ag, le, 250000, (m0 - make_interval(months => i) + interval '2 days')::date, 'orange_money', 'DEMO-' || i)
      returning id into pay;
      insert into payment_allocations (payment_id, rent_charge_id, agency_id, amount) values (pay, c, ag, 250000);
    end if;
  end loop;

  -- One repair in progress.
  insert into tickets (agency_id, building_id, apartment_id, resident_id, title, description, category, priority, status, location, reported_via)
  values (ag, bl, home, res, 'Fuite sous l''évier', 'L''eau coule sous l''évier de la cuisine quand le robinet est ouvert.',
          'plumbing', 'high', 'in_progress', 'Cuisine', 'app');

  raise notice 'demo agency created: %', ag;
end $$;

-- When real homes are published, hide the demo ones from Explore:
-- update apartments set listed = false
--  where agency_id = (select id from agencies where name = 'Charta Home Démo');
