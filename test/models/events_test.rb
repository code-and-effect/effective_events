require 'test_helper'

class EventsTest < ActiveSupport::TestCase
  test 'build_event is valid' do
    event = build_event()
    assert event.valid?

    assert_equal 3, event.event_tickets.length
    assert_equal 2, event.event_products.length

    event.event_tickets.each { |event_ticket| assert event.event_ticket_available?(event_ticket, quantity: 1) }
    event.event_products.each { |event_product| assert event.event_product_available?(event_product, quantity: 1) }

    refute event.draft?
    refute event.sold_out?
    refute event.closed?

    assert event.registerable?
  end

  test 'early bird' do
    now = Time.zone.now

    event = build_event()

    event.early_bird_end_at = nil
    refute event.early_bird?
    refute event.early_bird_past?

    event.early_bird_end_at = now + 1.minute
    assert event.early_bird?
    refute event.early_bird_past?

    event.early_bird_end_at = now
    refute event.early_bird?
    assert event.early_bird_past?
  end

end
