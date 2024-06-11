require 'test_helper'

class EventWaitlistTest < ActiveSupport::TestCase
  test 'event registration factories' do
    # Valiate Event factories
    event = build_waitlist_event()
    assert event.delayed_payment_date_upcoming?

    assert_equal 3, event.event_tickets.count
    assert event.event_tickets.all { |et| et.capacity == 5 }
    assert event.event_tickets.all { |et| et.waitlist? }

    # Validate Event Registration factories
    event_registration1 = build_event_registration(event: event, event_registrants: false, event_addons: false)
    event_registration2 = build_event_registration(event: event, event_registrants: false, event_addons: false)

    refute_equal event_registration1.owner, event_registration2.owner

    assert_equal 0, event_registration1.event_registrants.length
    assert_equal 0, event_registration1.event_addons.length

    assert_equal 0, event_registration2.event_registrants.length
    assert_equal 0, event_registration2.event_addons.length
  end

  test 'event registration waitlist on two registrations' do
    event = build_waitlist_event()
    event_ticket = event.event_tickets.first

    event_registration = build_event_registration(event: event, event_registrants: false, event_addons: false)

    6.times do |index|
      event_registration.event_registrant(
        event_ticket: event_ticket,
        first_name: "First #{index+1}",
        last_name: "Last #{index+1}",
        email: "registrant#{index+1}@effective_events.test"
      )
    end

    event_registration.ready!
    assert event_registration.draft?

    assert_equal 6, event_registration.event_registrants.length
    assert_equal 0, event_registration.event_registrants.count { |er| er.waitlisted? }
    assert_equal 600_00, event_registration.submit_order.subtotal

    event_registration.submit_order.delay!(payment: {}, payment_intent: 'asdf', provider: 'deluxe_delayed', card: 'Visa')

    event_registration.reload
    assert event_registration.submitted?

    assert_equal 5, event_registration.event_registrants.count { |er| !er.waitlisted? }
    assert_equal 1, event_registration.event_registrants.count { |er| er.waitlisted? }
    assert_equal 500_00, event_registration.submit_order.subtotal

    # Now build another registration should be waitlisted
    event_registration2 = build_event_registration(event: event, event_registrants: false, event_addons: false)

    1.times do |index|
      event_registration2.event_registrant(
        event_ticket: event_ticket,
        first_name: "First #{index+1}",
        last_name: "Last #{index+1}",
        email: "registrant#{index+1}@effective_events.test"
      )
    end

    event_registration2.ready!
    assert_equal 1, event_registration2.event_registrants.length
    assert_equal 0, event_registration2.event_registrants.count { |er| er.waitlisted? }
    assert_equal 100_00, event_registration2.submit_order.subtotal

    event_registration2.submit_order.delay!(payment: {}, payment_intent: 'asdf', provider: 'deluxe_delayed', card: 'Visa')

    event_registration2.reload
    assert event_registration2.submitted?

    assert_equal 1, event_registration2.event_registrants.count { |er| er.waitlisted? }
    assert_equal 0, event_registration2.submit_order.subtotal

    # Now remove some tickets from the first one. It should update the waitlist.
    event_registration.event_registrants.first.mark_for_destruction
    event_registration.event_registrants.second.mark_for_destruction
    event_registration.tickets!

    event_registration.reload
    assert_equal 4, event_registration.event_registrants.length
    assert_equal 4, event_registration.event_registrants.count { |er| !er.waitlisted? }
    assert_equal 4, event_registration.submit_order.order_items.length
    assert_equal 400_00, event_registration.submit_order.subtotal

    event_registration2.reload
    assert_equal 1, event_registration2.event_registrants.count { |er| !er.waitlisted? }
    assert_equal 100_00, event_registration2.submit_order.subtotal
  end

  test 'event registration waitlist with destroyed registration' do
    event = build_waitlist_event()
    event_ticket = event.event_tickets.first

    event_registration = build_event_registration(event: event, event_registrants: false, event_addons: false)

    6.times do |index|
      event_registration.event_registrant(
        event_ticket: event_ticket,
        first_name: "First #{index+1}",
        last_name: "Last #{index+1}",
        email: "registrant#{index+1}@effective_events.test"
      )
    end

    event_registration.ready!
    event_registration.submit_order.delay!(payment: {}, payment_intent: 'asdf', provider: 'deluxe_delayed', card: 'Visa')

    # Now build another registration should be waitlisted
    event_registration2 = build_event_registration(event: event, event_registrants: false, event_addons: false)

    1.times do |index|
      event_registration2.event_registrant(
        event_ticket: event_ticket,
        first_name: "First #{index+1}",
        last_name: "Last #{index+1}",
        email: "registrant#{index+1}@effective_events.test"
      )
    end

    event_registration2.ready!
    event_registration2.submit_order.delay!(payment: {}, payment_intent: 'asdf', provider: 'deluxe_delayed', card: 'Visa')

    event_registration2.reload
    assert_equal 1, event_registration2.event_registrants.count { |er| er.waitlisted? }

    # Destroying the first event registration will move the waitlisted registrant to the main list
    event_registration.destroy!

    event_registration2.reload
    assert_equal 1, event_registration2.event_registrants.count { |er| !er.waitlisted? }
    assert_equal 100_00, event_registration2.submit_order.subtotal
  end

end
