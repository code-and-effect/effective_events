require 'test_helper'

class EventRegistrantsTest < ActiveSupport::TestCase
  test 'regular pricing' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 800_00, order.subtotal
  end

  test 'early bird pricing' do
    event = build_event()
    event.update!(early_bird_end_at: Time.zone.now + 1.minute)

    event_registration = build_event_registration(event: event)
    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 650_00, order.subtotal
  end

  test 'member pricing' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.ready!

    event_registrant = event_registration.event_registrants.last
    assert_equal 200_00, event_registrant.price

    user = build_user()
    user.add_role!(:member)

    event_registrant.event_ticket.update!(category: 'Member or Non-Member', member_price: 50_00)
    event_registrant.update!(user: user)

    assert_equal 50_00, event_registrant.price
  end

  test 'member pricing with blank registrant' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.ready!

    event_registrant = event_registration.event_registrants.last
    assert_equal 200_00, event_registrant.price

    event_registrant.event_ticket.update!(category: 'Member or Non-Member', member_price: 50_00)
    event_registrant.update!(blank_registrant: true, member_registrant: true)

    assert_equal 50_00, event_registrant.price
  end

  test 'waitlist pricing' do
    event = build_waitlist_event()
    event_registration = build_event_registration(event: event)

    event_registrant = event_registration.event_registrants.first
    assert_equal 100_00, event_registrant.price

    event_registrant.update!(waitlisted: true)
    assert_equal 0, event_registrant.price

    event_registrant.update!(waitlisted: true, promoted: true)
    assert_equal 100_00, event_registrant.price

    event_registrant.update!(waitlisted: false, promoted: true)
    assert_equal 100_00, event_registrant.price
  end

end
