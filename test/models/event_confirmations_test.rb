require 'test_helper'

class EventConfirmationsTest < ActiveSupport::TestCase
  test 'event registration confirmation' do
    event_registration = build_event_registration()
    event_registration.event.update!(rich_text_confirmation_email: "<p>Test Content</p>")
    event_registration.ready!
    event_registration.submit_order.mark_as_purchased!

    assert_email(count: 2) do
      event_registration.send_order_emails!
    end

    email = ActionMailer::Base.deliveries.last
    assert email.body.include?("<p>Test Content</p>")
  end

  test 'event registrant confirmation' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.event.update!(rich_text_confirmation_email: "<p>Test Content</p>")
    event_registration.ready!
    event_registration.submit_order.mark_as_purchased!

    event_registrant = event_registration.event_registrants.last

    assert_email(count: 2) { event_registrant.send_order_emails! }

    email = ActionMailer::Base.deliveries.last
    assert email.body.include?("<p>Test Content</p>")
  end

  # https://github.com/code-and-effect/upside/issues/4413
  test 'an order with every ticket cancelled sends the cancelled email' do
    event_registration = build_delayed_event_registration()

    # Every ticket is cancelled
    EffectiveResources.transaction { event_registration.event_registrants.first.cancel_all! }
    event_registration.reload
    assert event_registration.event_registrants.all?(&:cancelled?)

    # Anything that sends the order emails from here on is a cancellation, not a confirmation.
    # This used to send "Your tickets have been confirmed!" with payment details and no tickets.
    assert_email(count: 2) { event_registration.submit_order.send_order_emails! }

    email = ActionMailer::Base.deliveries.last
    assert_equal "Tickets cancelled - #{event_registration.event}", email.subject
    assert email.body.include?("Your tickets have been cancelled")
    assert email.body.include?("No payments will be made for these tickets")
    assert_not email.body.include?("Please submit your cheque")
  end

  test 'an order with some tickets cancelled still sends the confirmation email' do
    event_registration = build_delayed_event_registration()

    EffectiveResources.transaction { event_registration.event_registrants.first.cancel! }
    event_registration.reload

    assert_email(count: 2) { event_registration.submit_order.send_order_emails! }

    email = ActionMailer::Base.deliveries.last
    assert_equal "Confirmation - #{event_registration.event}", email.subject
    assert email.body.include?("Your tickets have been confirmed!")
  end

  # https://github.com/code-and-effect/upside/issues/4249
  test 'a delayed order purchased before the delayed payment date sends the receipt email' do
    event_registration = build_delayed_event_registration(defer: false)

    order = event_registration.submit_order
    assert order.delayed_payment_date_upcoming?

    # They paid upfront instead of waiting for the delayed payment date
    assert_email(count: 2) { order.purchase! }

    email = ActionMailer::Base.deliveries.last
    assert_equal "Receipt - Order ##{order.to_param}", email.subject
    assert_not email.body.include?("Please submit your cheque")
  end

  # A delayed order stays delayed? after it's purchased, so the receipt subject must not
  # swallow the waitlist subjects. Otherwise the subject and the header contradict each other.
  test 'a purchased delayed order with waitlisted tickets keeps the waitlist subject' do
    event = build_waitlist_event()
    event_registration = build_event_registration(event: event)
    event_registration.event_registrants.first.update!(waitlisted: true)
    event_registration.ready!

    order = event_registration.submit_order
    assert order.delayed?

    assert_email(count: 2) { order.purchase! }
    assert order.delayed?, 'expected the order to still be delayed after purchase'

    email = ActionMailer::Base.deliveries.last
    assert_equal "Confirmation & Waitlist - #{event}", email.subject
    assert email.body.include?("Some of your tickets have been confirmed, but some are on the waitlist")
  end

  private

  def build_delayed_event_registration(defer: true)
    event = build_event()
    event.update!(delayed_payment: true, delayed_payment_date: (event.registration_end_at + 1.day).to_date)

    event_registration = build_event_registration(event: event)
    event_registration.ready!
    event_registration.submit_order.defer!(provider: 'cheque', email: false) if defer

    event_registration.reload
  end

end
