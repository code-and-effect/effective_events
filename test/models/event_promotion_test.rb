require 'test_helper'

class EventPromotionTest < ActiveSupport::TestCase
  test 'promote a registrant' do
    event = build_waitlist_event()

    event.event_tickets.each { |event_ticket| event_ticket.update!(capacity: 0, waitlist: true) }
    ticket = event.event_tickets.first!

    registration = build_event_registration(event: event, event_registrants: false)
    registration.event_ticket_selection(event_ticket: ticket, quantity: 4)
    registration.tickets!

    assert_equal 4, registration.event_registrants.count { |et| et.waitlisted? }
    registration.ready!
    registration.submit_order.purchase!

    registration.reload
    assert registration.event_registrants.all? { |er| er.registered? && er.purchased? && er.waitlisted? && !er.promoted? && er.price == 0 }

    # Now do the promote on one of them
    registrant = registration.event_registrants.last
    assert_equal registration, registrant.event_registration
    assert_equal registration.submit_order, registrant.purchased_order

    registrant.promote!
    registrant.reload

    refute_equal registration, registrant.event_registration
    refute_equal registration.submit_order, registrant.purchased_order

    assert registrant.registered?
    refute registrant.purchased?
    assert registrant.waitlisted?
    assert registrant.promoted?
    refute_equal 0, registrant.price

    # Check registrations
    registration.reload
    assert_equal 3, registration.event_registrants.count
    assert_equal 3, registration.submit_order.order_items.count { |oi| oi.purchasable_type == 'Effective::EventRegistrant' }

    registration2 = registrant.event_registration
    assert_equal 1, registration2.event_registrants.count
  end

end
