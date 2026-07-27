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
    # The buyer gets an updated order email with the completed registrant's name
    assert_email { EffectiveResources.transaction { event_registration.update_blank_registrants! } }

    blank_registrant.reload
    assert_not blank_registrant.blank_registrant?
    assert_equal existing_user, blank_registrant.user
  end

  test 'completing a blank registrant does not replace a declined submit order' do
    event = build_event()
    event.update!(delayed_payment: true, delayed_payment_date: (event.registration_end_at + 1.day).to_date)

    event_registration = build_event_registration(event: event)

    # One ticket is left blank: "leave details and come back later"
    event_registration.event_registrants.last.update!(blank_registrant: true)

    # Pay later: the submit_order is deferred and the registration is submitted
    event_registration.ready!
    event_registration.submit_order.defer!(provider: 'cheque', email: false)

    event_registration.reload
    assert event_registration.submitted?
    assert event_registration.submit_order.was_deferred?

    # The delayed payment runs on the delayed_payment_date and the card is declined
    submit_order = event_registration.submit_order
    submit_order.decline!
    assert submit_order.declined?

    # Owner returns to the submitted page and fills in the blank registrant's details
    blank_registrant = event_registration.event_registrants.detect(&:blank_registrant?)

    blank_registrant.assign_attributes(
      blank_registrant: false,
      user_type: 'User',
      first_name: 'Come',
      last_name: 'Back',
      email: 'comeback@effective_events.test'
    )

    # No order email. They were already told their payment was declined.
    assert_email(count: 0) { EffectiveResources.transaction { event_registration.update_blank_registrants! } }

    # Regression: this used to build a new pending order, which hid the declined one
    # and raised 'expected a deffered event_registration submit_order' on the submitted step
    event_registration.reload
    assert_equal 1, event_registration.orders.length
    assert_equal submit_order, event_registration.submit_order
    assert event_registration.submit_order.declined?
    assert event_registration.submit_order.was_deferred?

    # And the declined order still drives the checkout again flow.
    # ready! is called by the ready_checkout before_action when they revisit the checkout step
    assert event_registration.can_visit_step?(:checkout)
    event_registration.ready!

    # The registration is back to draft with a new order for the same fees
    event_registration.reload
    assert event_registration.draft?
    assert_equal 2, event_registration.orders.length

    order = event_registration.submit_order
    assert order.pending?
    assert_not_equal submit_order, order
    assert_equal submit_order.total, order.total

    # The completed registrant is on the new order
    assert order.order_items.any? { |order_item| order_item.name.include?('Come Back') }

    # And they can pay it. The registration is submitted again
    order.defer!(provider: 'cheque', email: false)
    assert event_registration.reload.submitted?
    assert event_registration.submit_order.was_deferred?
  end

  test 'an admin created registrant validates duplicates' do
    user = build_user_with_address()

    # The user is registered for every ticket on this event
    event_registration = build_event_registration()
    event = event_registration.event
    event_registration.event_registrants.each { |er| er.assign_attributes(user: user) }
    event_registration.ready!
    event_registration.submit_order.purchase!

    # An admin registers them again from the admin new event registrant form
    event_registrant = Effective::EventRegistrant.new(
      event: event,
      owner: user,
      user: user,
      event_ticket: event.event_tickets.last,
      registered_at: Time.zone.now,
      created_by_admin: true
    )

    assert event_registrant.validate_one_ticket_per_event?
    refute event_registrant.valid?

    assert_equal ["Unable to register #{user} for #{event}. They've already been registered"], event_registrant.errors[:user_id]
  end
end
