require 'test_helper'

class EventsTest < ActiveSupport::TestCase
  test 'build_event is valid' do
    event = build_event()
    assert event.valid?

    assert_equal 3, event.event_tickets.length
    assert_equal 2, event.event_products.length

    event.event_tickets.each { |event_ticket| assert event_ticket.available? }
    event.event_products.each { |event_product| assert event_product.available? }

    refute event.draft?
    refute event.sold_out?
    refute event.closed?

    assert event.registerable?
  end

end
