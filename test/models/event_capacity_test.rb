require 'test_helper'

class EventCapacityTest < ActiveSupport::TestCase
  test 'event tickets have capacity' do
    ticket = build_event_ticket()
    ticket.capacity = 3
    ticket.save!

    assert ticket.available?
    assert_equal 0, ticket.purchased_event_registrants_count
    assert_equal 3, ticket.capacity_available

    registrant = build_event_registrant(event_ticket: ticket, event: ticket.event)
    registrant2 = build_event_registrant(event_ticket: ticket, event: ticket.event)
    registrant3 = build_event_registrant(event_ticket: ticket, event: ticket.event)

    registrant.save!
    registrant2.save!
    registrant3.save!

    order = Effective::Order.new(items: [registrant, registrant2, registrant3], user: registrant.owner)
    order.purchase!

    ticket.reload

    refute ticket.available?
    assert_equal 3, ticket.purchased_event_registrants_count
    assert_equal 0, ticket.capacity_available
  end

  test 'event products have capacity' do
    product = build_event_product()
    product.capacity = 3
    product.save!

    assert product.available?
    assert_equal 0, product.purchased_event_addons_count
    assert_equal 3, product.capacity_available

    addon = build_event_addon(event_product: product, event: product.event)
    addon2 = build_event_addon(event_product: product, event: product.event)
    addon3 = build_event_addon(event_product: product, event: product.event)

    addon.save!
    addon2.save!
    addon3.save!

    order = Effective::Order.new(items: [addon, addon2, addon3], user: addon.owner)
    order.purchase!

    product.reload

    refute product.available?
    assert_equal 3, product.purchased_event_addons_count
    assert_equal 0, product.capacity_available
  end

  # test 'event registrations validate ticket capacity' do
  #   event_registration = build_event_registration()

  #   event_registration.event_registrants.first.event_ticket.update!(capacity: 0)
  #   refute event_registration.save

  #   assert event_registration.errors[:base].to_s.include?('no longer available for purchase')
  #   assert event_registration.event_registrants.first.errors[:event_ticket_id].to_s.include?('unavailable')
  # end

  # test 'event registrations validate product capacity' do
  #   event_registration = build_event_registration()

  #   event_registration.event_addons.first.event_product.update!(capacity: 0)
  #   refute event_registration.save

  #   assert event_registration.errors[:base].to_s.include?('no longer available for purchase')
  #   assert event_registration.event_addons.first.errors[:event_product_id].to_s.include?('unavailable')
  # end


end
