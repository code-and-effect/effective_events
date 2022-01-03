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

  def create_event
    build_event().tap { |event| event.save! }
  end

  def build_event
    now = Time.zone.now

    event = Effective::Event.new(
      title: "#{now.year} Main Event",
      except: '<p>This is a great event!</p>',
      body: '<p>This is really a great event!</p>',

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

    event
  end

  # def build_event_ticket
  #   event ||= build_event()

  #   Effective::EventTicket.new(
  #     event: event,
  #     title: 'Test Event Ticket',
  #     regular_price: 100_00,
  #     early_bird_price: 50_00,
  #     tax_exempt: false
  #   )
  # end

  # def build_event_registrant
  #   user ||= build_user()
  #   event ||= build_event()
  #   event_ticket ||= build_event_ticket()

  #   Effective::EventRegistrant.new(
  #     user: user,
  #     event: event,
  #     event_ticket: event_ticket,
  #     first_name: "Joe",
  #     last_name: "Dirt",
  #     email: "joe@dirt.com",
  #     company: "JD Inc.",
  #     number: "648593"
  #   )
  # end

end
