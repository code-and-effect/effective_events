require 'test_helper'

class EventRegistrationsTest < ActiveSupport::TestCase
  test 'build_event_registration is valid' do
    event_registration = build_event_registration()
    assert event_registration.valid?

    assert_equal 3, event_registration.event_registrants.length
    assert_equal 2, event_registration.event_purchases.length
  end

  test 'build_event_registration purchase' do
    event_registration = build_event_registration()

    event_registration.ready!
    order = event_registration.submit_order

    assert order.present?
    assert_equal 5, order.order_items.length
    assert_equal event_registration.submit_fees, order.purchasables

    assert_equal event_registration.submit_fees.sum(&:price), order.subtotal
    order.purchase!

    event_registration.reload
    assert event_registration.submitted?
    assert event_registration.done?
  end

  test 'build_event_registration move and remove items' do
    event_registration = build_event_registration()
    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 5, order.order_items.length
    assert_equal 800_00, order.subtotal

    event_registration.event_registrants.last.destroy!
    event_registration.reload

    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 4, order.order_items.length
    assert_equal 600_00, order.subtotal
  end

end
