require 'test_helper'

class EventSearchTest < ActiveSupport::TestCase

  test 'shows upcoming events' do
    Effective::Event.delete_all

    event_1 = create_event_by('Yesterday',  1.day.ago)
    event_2 = create_event_by('Tomorrow',   1.day.from_now)
    event_3 = create_event_by('Next Month', 1.month.from_now)
    event_4 = create_event_by('Hidden', 2.months.from_now).tap { |event| event.update!(hidden: true) }
    event_5 = create_event_by('Draft', 3.months.from_now).tap(&:draft!)

    search = ::Effective::EventSearch.new
    search.search!
    events = search.results

    assert_equal events.pluck(:id), [event_2.id, event_3.id]

    admin_search = ::Effective::EventSearch.new(unpublished: true)
    admin_search.search!

    assert_equal admin_search.results.pluck(:id), [event_2.id, event_3.id, event_4.id, event_5.id]
  end

end
