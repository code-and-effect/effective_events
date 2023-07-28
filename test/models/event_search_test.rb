require 'test_helper'

class EventSearchTest < ActiveSupport::TestCase

  test 'shows upcoming events' do
    Effective::Event.delete_all

    event_1 = create_event_by('Yesterday',  1.day.ago)
    event_2 = create_event_by('Tomorrow',   1.day.from_now)
    event_3 = create_event_by('Next Month', 1.month.from_now)

    search = ::Effective::EventSearch.new
    search.search!
    events = search.results

    assert_equal events.pluck(:id), [event_2.id, event_3.id]
  end

end
