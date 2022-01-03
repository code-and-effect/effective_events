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

  def build_event
    Effective::Event.new(
      title: 'Test Event',
      body: 'Test Event Body',
      start_at: Time.zone.now + 5.days,
      end_at: Time.zone.now + 5.days + 8.hours,
      registration_start_at: Time.zone.now - 1.week,
      registration_end_at: Time.zone.now + 3.days,
      early_bird_end_at: Time.zone.now
    )
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

  def build_event_registrant
    user ||= build_user()
    event ||= build_event()
    event_ticket ||= build_event_ticket()

    Effective::EventRegistrant.new(
      user: user,
      event: event,
      event_ticket: event_ticket,
      first_name: "Joe",
      last_name: "Dirt",
      email: "joe@dirt.com",
      company: "JD Inc.",
      number: "648593"
    )
  end

end
