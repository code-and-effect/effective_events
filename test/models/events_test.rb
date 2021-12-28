require 'test_helper'

class EventsTest < ActiveSupport::TestCase
  test 'event' do
    event = build_event()
    assert event.valid?
  end

end
