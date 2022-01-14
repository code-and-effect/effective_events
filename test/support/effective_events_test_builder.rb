module EffectiveEventsTestBuilder

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_user_with_address
    user = build_user()

    user.addresses.build(
      addressable: user,
      category: 'billing',
      full_name: 'Test User',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    user.save!
    user
  end

  def create_event
    build_event().tap { |event| event.save! }
  end

  def build_event
    now = Time.zone.now

    event = Effective::Event.new(
      title: "#{now.year} Main Event",
      rich_text_excerpt: '<p>This is a great event!</p>',
      rich_text_body: '<p>This is really a great event!</p>',

      start_at: (now + 1.week),
      end_at: (now + 1.week + 1.hour),

      registration_start_at: now,
      registration_end_at: (now + 6.days),
      early_bird_end_at: (now + 3.days)
    )

    event.event_tickets.build(
      title: 'Ticket A 10 Seats',
      capacity: 10,
      regular_price: 100_00,
      early_bird_price: 50_00,
      qb_item_name: 'Tickets'
    )

    event.event_tickets.build(
      title: 'Ticket B 20 Seats',
      capacity: 20,
      regular_price: 200_00,
      early_bird_price: 150_00,
      qb_item_name: 'Tickets'
    )

    event.event_tickets.build(
      title: 'Ticket C Unlimited Seats',
      capacity: nil,
      regular_price: 200_00,
      early_bird_price: 150_00,
      qb_item_name: 'Tickets'
    )

    event.event_products.build(
      title: 'Product A 10 Available',
      capacity: 20,
      price: 100_00,
      qb_item_name: 'Products'
    )

    event.event_products.build(
      title: 'Product B Unlimited',
      capacity: nil,
      price: 200_00,
      qb_item_name: 'Products'
    )

    event
  end

  def build_event_registration(owner: nil, event: nil)
    event ||= build_event()
    owner ||= build_user_with_address()

    event_registration = Effective::EventRegistration.new(
      event: event,
      owner: owner
    )

    event_registration.event.event_tickets.each_with_index do |event_ticket, index|
      event_registration.event_registrant(
        event_ticket: event_ticket,
        first_name: "First",
        last_name: "Last #{index+1}",
        email: "registrant#{index+1}@effective_events.test"
      )
    end

    event_registration.event.event_products.each_with_index do |event_product, index|
      event_registration.event_addon(event_product: event_product)
    end

    event_registration.save!

    event_registration
  end

  def build_event_ticket
    event ||= build_event()

    Effective::EventTicket.new(
      event: event,
      title: 'Test Event Ticket',
      regular_price: 100_00,
      early_bird_price: 50_00,
      tax_exempt: false
    )
  end

  def build_event_product
    event ||= build_event()

    Effective::EventProduct.new(
      event: event,
      title: 'Test Event Product',
      price: 100_00,
    )
  end

  def build_event_registrant(owner: nil, event: nil, event_ticket: nil)
    owner ||= build_user_with_address()
    event ||= build_event()
    event_ticket ||= build_event_ticket()

    Effective::EventRegistrant.new(
      owner: owner,
      event: event,
      event_ticket: event_ticket,
      first_name: "Joe",
      last_name: "Dirt",
      email: "joe@dirt.com",
      company: "JD Inc.",
      number: "648593"
    )
  end

  def build_event_addon(owner: nil, event: nil, event_product: nil)
    owner ||= build_user_with_address()
    event ||= build_event()
    event_product ||= build_event_product()

    Effective::EventAddon.new(
      owner: owner,
      event: event,
      event_product: event_product,
    )
  end

end
