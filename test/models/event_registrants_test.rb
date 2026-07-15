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

    event_registrant.event_ticket.update!(category: 'Anyone', member_price: 50_00)
    event_registrant.update!(user: user)

    assert_equal 50_00, event_registrant.price
  end

  test 'member pricing with blank registrant' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.ready!

    event_registrant = event_registration.event_registrants.last
    assert_equal 200_00, event_registrant.price

    event_registrant.event_ticket.update!(category: 'Anyone', member_price: 50_00)
    event_registrant.update!(blank_registrant: true)

    assert_equal 200_00, event_registrant.price
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

  test 'archived pricing' do
    event = build_waitlist_event()
    event_registration = build_event_registration(event: event)

    event_registrant = event_registration.event_registrants.first
    assert_equal 100_00, event_registrant.price

    event_registrant.archive!
    assert_equal 0, event_registrant.price

    event_registrant.unarchive!
    assert_equal 100_00, event_registrant.price
  end

  test 'completing a purchased blank registrant links the user without raising' do
    # The attendee who will be linked when the blank registrant is completed
    existing_user = create_user!
    existing_user.update!(email: 'comeback@effective_events.test')

    event = build_event()
    event_registration = build_event_registration(event: event)

    # One ticket is left blank: "leave details and come back later"
    blank_registrant = event_registration.event_registrants.last
    blank_registrant.update!(blank_registrant: true)
    assert blank_registrant.blank_registrant?
    assert blank_registrant.first_name.blank?

    # Pay upfront: the submit_order is purchased and the blank registrant becomes purchased
    event_registration.ready!
    event_registration.submit_order.purchase!

    event_registration.reload
    blank_registrant = event_registration.event_registrants.detect(&:blank_registrant?)
    assert blank_registrant.purchased?

    # Owner returns to the completed page and fills in the blank registrant's details.
    # The form resubmits user_type (a hidden field), which Rails nils out while blank.
    blank_registrant.assign_attributes(
      blank_registrant: false,
      user_type: 'User',
      first_name: 'Come',
      last_name: 'Back',
      email: 'comeback@effective_events.test'
    )

    # Regression: build_user used to raise 'is already purchased' here
    assert_nothing_raised { event_registration.update_blank_registrants! }

    blank_registrant.reload
    assert_not blank_registrant.blank_registrant?
    assert_equal existing_user, blank_registrant.user
  end
end
