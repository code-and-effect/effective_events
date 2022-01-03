require 'test_helper'

class EventsTest < ActiveSupport::TestCase
  test 'build_event is valid' do
    event = build_event()
    assert event.valid?
  end

  test 'build_event_ticket is valid' do
    event_ticket = build_event_ticket()
    assert event_ticket.valid?
  end

  test 'build_event_registrant is valid' do
    event_registrant = build_event_registrant()
    assert event_registrant.valid?
  end
end
