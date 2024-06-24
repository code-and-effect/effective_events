module EffectiveEventsTestBuilder

  def create_event_by(name, end_at)
    Effective::Event.create!(
      title: name,
      published_at: Date.yesterday,
      start_at: 1.month.ago,
      end_at: end_at,
      registration_start_at: 1.month.ago - 1,
      registration_end_at: Date.today
    )
  end


  def create_event
    build_event().tap { |event| event.save! }
  end

  def build_waitlist_event
    event = build_event()

    delayed_payment_date = (event.registration_end_at + 1.day).to_date

    event.assign_attributes(delayed_payment: true, delayed_payment_date: delayed_payment_date)
    event.event_tickets.each { |event_ticket| event_ticket.assign_attributes(capacity: 5, waitlist: true) }
    event.save!

    event
  end

  def build_event
    now = Time.zone.now

    event = Effective::Event.new(
      title: "#{now.year} Main Event",
      rich_text_excerpt: '<p>This is a great event!</p>',
      rich_text_body: '<p>This is really a great event!</p>',

      published_at: Time.zone.now,
      start_at: (now + 1.week),
      end_at: (now + 1.week + 1.hour),

      registration_start_at: now,
      registration_end_at: (now + 6.days),
      early_bird_end_at: nil
    )

    event.event_tickets.build(
      title: 'Ticket A 10 Seats',
      category: 'Regular',
      capacity: 10,
      regular_price: 100_00,
      early_bird_price: 50_00,
      member_price: 75_00,
      qb_item_name: 'Tickets'
    )

    event.event_tickets.build(
      title: 'Ticket B 20 Seats',
      category: 'Regular',
      capacity: 20,
      regular_price: 200_00,
      early_bird_price: 150_00,
      member_price: 75_00,
      qb_item_name: 'Tickets'
    )

    event.event_tickets.build(
      title: 'Ticket C Unlimited Seats',
      category: 'Regular',
      capacity: nil,
      regular_price: 200_00,
      early_bird_price: 150_00,
      member_price: 75_00,
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

  def build_event_registration(owner: nil, event: nil, event_registrants: true, event_addons: true)
    event ||= build_event()
    owner ||= build_user_with_address()

    event_registration = Effective::EventRegistration.new(
      event: event,
      owner: owner
    )

    if event_registrants
      event_registration.event.event_tickets.each_with_index do |event_ticket, index|
        event_registration.event_registrant(
          event_ticket: event_ticket,
          first_name: "First",
          last_name: "Last #{index+1}",
          email: "registrant#{index+1}@effective_events.test"
        )
      end
    end

    if event_addons
      event_registration.event.event_products.each_with_index do |event_product, index|
        event_registration.event_addon(
          event_product: event_product,
          first_name: "First",
          last_name: "Last #{index+1}",
          email: "registrant#{index+1}@effective_events.test"
        )
      end
    end

    event_registration.save!

    event_registration
  end

  def build_event_ticket
    event ||= build_event()

    Effective::EventTicket.new(
      event: event,
      title: 'Test Event Ticket',
      category: 'Regular',
      regular_price: 100_00,
      member_price: 75_00,
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
      first_name: "Joe",
      last_name: "Dirt",
      email: "joe@dirt.com"
    )
  end

  def build_event_notification(owner: nil, event: nil, category: nil)
    owner ||= build_user_with_address()
    event ||= build_event()
    category ||= 'Registrant purchased'

    Effective::EventNotification.new(
      category: category,
      event: event,
      reminder: 1.day.to_i,
      from: 'noreply@example.com',
      subject: "#{category} subject",
      body: "#{category} body",
      content_type: "text/plain"
    )
  end

end
