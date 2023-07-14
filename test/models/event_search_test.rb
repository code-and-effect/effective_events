require 'test_helper'

class EventSearchTest < ActiveSupport::TestCase

  # ArgumentError: wrong number of arguments (given 1, expected 0)
  # /Users/momente/Projects/CodeAndEffect/Gems/effective_events/app/models/effective/event.rb:98:in

  # test 'shows upcoming events' do
  #   event_1 = create_event_by('Yesterday',  1.day.ago)
  #   event_2 = create_event_by('Tomorrow',   1.day.from_now)
  #   event_3 = create_event_by('Next Month', 1.month.from_now)

  #   search = ::Effective::EventSearch.new
  #   search.search!
  #   events = search.results

  #   assert_equal events.pluck(:id), [event_2, event_3]
  # end

end
