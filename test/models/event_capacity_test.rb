require 'test_helper'

class EventCapacityTest < ActiveSupport::TestCase
  test 'event tickets have capacity' do
    ticket = build_event_ticket()
    ticket.capacity = 3
    ticket.save!

    event = ticket.event

    assert event.event_ticket_available?(ticket, quantity: 3)
    refute event.event_ticket_available?(ticket, quantity: 4)

    assert_equal 0, ticket.purchased_event_registrants_count

    registrant = build_event_registrant(event_ticket: ticket, event: event)
    registrant2 = build_event_registrant(event_ticket: ticket, event: event)
    registrant3 = build_event_registrant(event_ticket: ticket, event: event)

    registrant.save!
    registrant2.save!
    registrant3.save!

    refute registrant.registered?
    refute registrant2.registered?
    refute registrant3.registered?

    order = Effective::Order.new(items: [registrant, registrant2, registrant3], user: registrant.owner)
    order.purchase!

    assert registrant.registered?
    assert registrant2.registered?
    assert registrant3.registered?

    ticket.reload
    event = ticket.event

    refute event.event_ticket_available?(ticket, quantity: 1)
    assert_equal 3, ticket.purchased_event_registrants_count
  end

  test 'event products have capacity' do
    product = build_event_product()
    product.capacity = 3
    product.save!

    event = product.event

    assert event.event_product_available?(product, quantity: 3)
    refute event.event_product_available?(product, quantity: 4)
    assert_equal 0, product.purchased_event_addons_count

    addon = build_event_addon(event_product: product, event: event)
    addon2 = build_event_addon(event_product: product, event: event)
    addon3 = build_event_addon(event_product: product, event: event)

    addon.save!
    addon2.save!
    addon3.save!

    order = Effective::Order.new(items: [addon, addon2, addon3], user: addon.owner)
    order.purchase!

    product.reload
    event = product.event

    refute event.event_product_available?(product, quantity: 1)
    assert_equal 3, product.purchased_event_addons_count
  end

end
