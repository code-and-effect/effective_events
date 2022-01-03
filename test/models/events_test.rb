require 'test_helper'

class EventsTest < ActiveSupport::TestCase
  test 'build_event is valid' do
    event = build_event()
    assert event.valid?

    assert_equal 3, event.event_tickets.length

    refute event.draft?
    refute event.sold_out?
    refute event.closed?

    assert event.registerable?
  end

end
