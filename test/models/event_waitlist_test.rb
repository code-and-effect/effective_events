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

  test 'assigning waitlist' do
    selection_window = EffectiveEvents.EventRegistration.selection_window

    event = build_waitlist_event()

    ticket = event.event_tickets.first!
    assert ticket.waitlist?
    assert_equal 5, ticket.capacity

    reg1 = build_event_registration(event: event, event_registrants: false)
    reg2 = build_event_registration(event: event, event_registrants: false)

    assert event.event_ticket_available?(ticket, quantity: 5)
    assert_equal 5, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 0, event.capacity_taken(event_ticket: ticket, event_registration: reg1)

    # Select tickets in reg1
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 4)
    reg1.tickets!
    ticket.reload

    assert_equal 4, reg1.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 0, reg1.event_registrants.count { |et| et.waitlisted? }

    assert_equal 5, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 4, event.capacity_taken(event_ticket: ticket)

    # Select tickets in reg2
    reg2.event_ticket_selection(event_ticket: ticket, quantity: 4)
    reg2.tickets!
    ticket.reload

    assert_equal 1, reg2.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 3, reg2.event_registrants.count { |et| et.waitlisted? }

    assert_equal 1, event.capacity_available(event_ticket: ticket, event_registration: reg2)
    assert_equal 4, event.capacity_taken(event_ticket: ticket, event_registration: reg2)
    assert_equal 0, event.capacity_available(event_ticket: ticket)

    reg2.event_registrants.each { |er| er.destroy }
    reg2.reload

    # Now go 20 minutes in the future
    with_time_travel(Time.zone.now + selection_window) do
      reg2.event_ticket_selection(event_ticket: ticket, quantity: 4)
      reg2.tickets!
      ticket.reload

      assert_equal 4, reg2.event_registrants.count { |et| !et.waitlisted? }
      assert_equal 0, reg2.event_registrants.count { |et| et.waitlisted? }

      assert_equal 1, event.capacity_available(event_ticket: ticket)
      assert_equal 4, event.capacity_taken(event_ticket: ticket)
    end
  end

  test 'assigning waitlist with existing waitlisted registrants' do
    selection_window = EffectiveEvents.EventRegistration.selection_window

    event = build_waitlist_event()

    ticket = event.event_tickets.first!
    assert ticket.waitlist?
    assert_equal 5, ticket.capacity

    reg1 = build_event_registration(event: event, event_registrants: false)
    reg2 = build_event_registration(event: event, event_registrants: false)

    assert event.event_ticket_available?(ticket, quantity: 5)
    assert_equal 5, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 0, event.capacity_taken(event_ticket: ticket, event_registration: reg1)

    # Select tickets in reg1
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 4)
    reg1.tickets!
    ticket.reload

    assert_equal 4, reg1.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 0, reg1.event_registrants.count { |et| et.waitlisted? }

    assert_equal 5, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 4, event.capacity_taken(event_ticket: ticket)

    # Select tickets in reg2
    reg2.event_ticket_selection(event_ticket: ticket, quantity: 4)
    reg2.tickets!
    ticket.reload

    assert_equal 1, reg2.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 3, reg2.event_registrants.count { |et| et.waitlisted? }

    assert_equal 1, event.capacity_available(event_ticket: ticket, event_registration: reg2)
    assert_equal 4, event.capacity_taken(event_ticket: ticket, event_registration: reg2)
    assert_equal 0, event.capacity_available(event_ticket: ticket)

    reg2.event_registrants.find { |er| !er.waitlisted? }.mark_for_destruction
    assert_email(:event_capacity_released) { reg2.tickets! }

    # Now go 20 minutes in the future
    with_time_travel(Time.zone.now + selection_window) do
      # This has at least one waitlisted registrant. So the additional tickets will be all waitlisted
      assert reg2.event_registrants.find { |er| er.waitlisted_not_promoted? }.present?

      reg2.event_ticket_selection(event_ticket: ticket, quantity: 4)
      reg2.tickets!
      ticket.reload

      assert_equal 0, reg2.event_registrants.count { |et| !et.waitlisted? }
      assert_equal 4, reg2.event_registrants.count { |et| et.waitlisted? }

      assert_equal 5, event.capacity_available(event_ticket: ticket)
    end
  end

  test 'assigning waitlist with existing waitlisted registrants again' do
    selection_window = EffectiveEvents.EventRegistration.selection_window

    event = build_waitlist_event()

    ticket = event.event_tickets.first!
    assert ticket.waitlist?
    assert_equal 5, ticket.capacity

    reg1 = build_event_registration(event: event, event_registrants: false)

    assert event.event_ticket_available?(ticket, quantity: 5)
    assert_equal 5, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 0, event.capacity_taken(event_ticket: ticket, event_registration: reg1)

    # Select tickets in reg1
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 5)
    reg1.tickets!
    reg1.ready!
    reg1.submit_order.defer!(provider: 'cheque')

    reg1.reload
    ticket.reload

    assert_equal 5, reg1.event_registrants.count { |et| et.registered? }
    assert_equal 5, reg1.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 0, reg1.event_registrants.count { |et| et.waitlisted? }

    # Now go back for more tickets
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 7)
    reg1.tickets!

    assert_equal 7, reg1.event_registrants.count { |et| et.registered? }
    assert_equal 5, reg1.event_registrants.count { |et| !et.waitlisted? }
    assert_equal 2, reg1.event_registrants.count { |et| et.waitlisted? }
  end

end
