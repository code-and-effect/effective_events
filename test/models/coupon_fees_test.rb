require 'test_helper'

class CouponFeesTest < ActiveSupport::TestCase
  test 'build_event_registration purchase' do
    event = build_event()
    event.event_tickets.each { |ticket| ticket.update!(non_member_price: 10_00, early_bird_price: 10_00) }
    event.event_products.each { |product| product.update!(price: 10_00) }

    owner = build_user_with_address()

    event_registration = build_event_registration(event: event, owner: owner)
    event_registration.ready!

    assert_equal 50_00, event_registration.submit_fees.sum(&:price)
    assert_equal 0, event_registration.submit_fees.count { |fee| fee.try(:coupon_fee?) }

    assert event_registration.submit_order.purchase!
  end

  test 'coupon fees for regular order' do
    event = build_event()
    event.event_tickets.each { |ticket| ticket.update!(non_member_price: 10_00, early_bird_price: 10_00) }
    event.event_products.each { |product| product.update!(price: 10_00) }

    owner = build_user_with_address()

    # Now build a Coupon free
    period = EffectiveMemberships.Registrar.current_period
    fee = owner.build_title_fee(title: 'Great Coupon', fee_type: 'Coupon', period: period, category: nil, price: -65_00, qb_item_name: 'Great Coupon Name')
    fee.save!

    owner.reload
    assert_equal 1, owner.outstanding_coupon_fees.count

    event_registration = build_event_registration(event: event, owner: owner)
    event_registration.ready!

    assert_equal 6, event_registration.submit_fees.count
    assert_equal 5, event_registration.submit_fees.count { |fee| !fee.try(:coupon_fee?) }
    assert_equal 1, event_registration.submit_fees.count { |fee| fee.try(:coupon_fee?) }

    assert_equal (50_00 - 65_00), event_registration.submit_fees.sum(&:price)
    assert_equal 0, event_registration.submit_order.subtotal
    assert event_registration.submit_order.purchase!

    owner.reload
    assert_equal 0, owner.outstanding_coupon_fees.count
  end

  test 'coupon fees for zero dollar order' do
    event = build_event()
    event.event_tickets.each { |ticket| ticket.update!(non_member_price: 0, early_bird_price: 0) }
    event.event_products.each { |product| product.update!(price: 0) }

    owner = build_user_with_address()

    # Now build a Coupon free
    period = EffectiveMemberships.Registrar.current_period
    fee = owner.build_title_fee(title: 'Great Coupon', fee_type: 'Coupon', period: period, category: nil, price: -65_00, qb_item_name: 'Great Coupon Name')
    fee.save!

    owner.reload
    assert_equal 1, owner.outstanding_coupon_fees.count

    event_registration = build_event_registration(event: event, owner: owner)
    event_registration.ready!

    assert_equal 0, event_registration.submit_fees.sum(&:price)

    assert_equal 5, event_registration.submit_fees.count
    assert_equal 0, event_registration.submit_fees.count { |fee| fee.try(:coupon_fee?) }

    assert_equal 0, event_registration.submit_order.subtotal
    assert event_registration.submit_order.purchase!

    owner.reload
    assert_equal 1, owner.outstanding_coupon_fees.count
  end

end
