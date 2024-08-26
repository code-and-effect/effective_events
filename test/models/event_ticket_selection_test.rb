require 'test_helper'

class EventTicketSelectionTest < ActiveSupport::TestCase
  test 'event selection creates event registrants' do
    registration = build_event_registration(event_registrants: false)
    ticket = registration.event.event_tickets.first!

    assert_equal 0, registration.event_registrants.count

    # Select tickets in reg1
    registration.assign_attributes(current_step: :tickets)
    registration.event_ticket_selection(event_ticket: ticket, quantity: 3)

    registration.tickets!
    assert_equal 3, registration.event_registrants.count

    selection = registration.event_ticket_selection(event_ticket: ticket)
    selection.assign_attributes(quantity: 1)

    registration.tickets!
    assert_equal 1, registration.event_registrants.count
  end

  test 'event selection window with 3 capacity' do
    selection_window = EffectiveEvents.EventRegistration.selection_window
    assert_equal 30.minutes, selection_window

    ticket = build_event_ticket()
    event = ticket.event

    ticket.update!(capacity: 3, waitlist: false)

    reg1 = build_event_registration(event: event, event_registrants: false)
    reg2 = build_event_registration(event: event, event_registrants: false)

    assert event.event_ticket_available?(ticket, quantity: 3)

    # Select tickets in reg1
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 2)
    reg1.tickets!
    ticket.reload

    assert event.event_ticket_available?(ticket, quantity: 1)

    assert_equal 2, ticket.capacity_taken
    assert_equal 1, ticket.capacity_available

    assert_equal 0, ticket.capacity_taken(except: reg1)
    assert_equal 2, ticket.capacity_taken(except: reg2)

    assert_equal 3, ticket.capacity_available(except: reg1)
    assert_equal 1, ticket.capacity_available(except: reg2)

    assert_equal 3, event.capacity_available(event_ticket: ticket, event_registration: reg1)
    assert_equal 1, event.capacity_available(event_ticket: ticket, event_registration: reg2)

    assert_equal 3, event.capacity_selectable(event_ticket: ticket, event_registration: reg1)
    assert_equal 1, event.capacity_selectable(event_ticket: ticket, event_registration: reg2)

    assert event.event_ticket_available?(ticket, quantity: 1)
    assert event.event_ticket_available?(ticket, quantity: 3, except: reg1)
    assert event.event_ticket_available?(ticket, quantity: 1, except: reg2)

    refute event.event_ticket_available?(ticket, quantity: 2)
    refute event.event_ticket_available?(ticket, quantity: 4, except: reg1)
    refute event.event_ticket_available?(ticket, quantity: 2, except: reg2)

    # Now go 20 minutes in the future
    with_time_travel(Time.zone.now + selection_window) do
      assert_equal 0, ticket.capacity_taken
      assert_equal 3, ticket.capacity_available

      assert_equal 0, ticket.capacity_taken(except: reg1)
      assert_equal 0, ticket.capacity_taken(except: reg2)

      assert_equal 3, ticket.capacity_available(except: reg1)
      assert_equal 3, ticket.capacity_available(except: reg2)

      assert_equal 3, event.capacity_available(event_ticket: ticket, event_registration: reg1)
      assert_equal 3, event.capacity_available(event_ticket: ticket, event_registration: reg2)

      assert event.event_ticket_available?(ticket, quantity: 3)
      assert event.event_ticket_available?(ticket, quantity: 3, except: reg1)
      assert event.event_ticket_available?(ticket, quantity: 3, except: reg2)
    end
  end

  test 'two registrations both want 2 tickets but there are only 3 available' do
    selection_window = EffectiveEvents.EventRegistration.selection_window

    ticket = build_event_ticket()
    event = ticket.event

    ticket.update!(capacity: 3, waitlist: false)
    reg1 = build_event_registration(event: event, event_registrants: false)
    reg2 = build_event_registration(event: event, event_registrants: false)

    assert event.event_ticket_available?(ticket, quantity: 3)

    # Registration 1 selects two tickets
    reg1.event_ticket_selection(event_ticket: ticket, quantity: 2)
    assert reg1.tickets!
    ticket.reload

    # Registration 2 can no longer do that
    reg2.event_ticket_selection(event_ticket: ticket, quantity: 2)

    assert_equal :invalid, (reg2.tickets! rescue :invalid)
    assert_equal [ticket], reg2.unavailable_event_tickets()

    with_time_travel(Time.zone.now + selection_window) do
      assert reg2.tickets!
    end
  end

end
