require 'test_helper'

class EventRegistrationsTest < ActiveSupport::TestCase
  test 'build_event_registration is valid' do
    event_registration = build_event_registration()
    assert event_registration.valid?

    assert_equal 3, event_registration.event_registrants.length
    assert_equal 2, event_registration.event_addons.length
  end

  test 'event registration with delayed payment date' do
    event_registration = build_event_registration()
    delayed_payment_attributes = { delayed_payment: true, delayed_payment_date: (event_registration.event.registration_end_at + 1.day).to_date }

    event_registration.event.assign_attributes(delayed_payment_attributes)
    assert_equal delayed_payment_attributes, event_registration.delayed_payment_attributes
  end

  test 'event with external registration is invalid for registration' do
    event_registration = build_event_registration()
    event_registration.event.update_column(:external_registration, true)
    refute event_registration.valid?
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
    assert event_registration.was_submitted?
    assert event_registration.completed?
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

  test 'regular pricing' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 800_00, order.subtotal
  end

  test 'early bird pricing' do
    event = build_event()
    event.update!(early_bird_end_at: Time.zone.now + 1.minute)

    event_registration = build_event_registration(event: event)
    event_registration.ready!

    order = event_registration.submit_order
    assert_equal 650_00, order.subtotal
  end

  test 'sends order receipt emails on event registration purchase' do
    event_registration = build_event_registration()

    event_registration.ready!
    order = event_registration.submit_order

    # 1 order email to user, 1 order email to admin
    assert_email(count: 2) { order.purchase! }
  end

  test 'sends order receipt emails AND event notifications on event registration purchase' do
    event_registration = build_event_registration()

    event = event_registration.event
    category = 'Registrant purchased'

    Effective::EventNotification.create!(
      category: category,
      event: event,
      from: 'noreply@example.com',
      subject: "#{category} subject",
      body: "#{category} body"
    )

    event_registration.ready!
    order = event_registration.submit_order

    # 1 order email to user, 1 order email to admin
    # Plus 3 registrant emails
    assert_email(count: 5) { order.purchase! }
  end

end
