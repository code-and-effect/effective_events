require 'test_helper'

class EventConfirmationsTest < ActiveSupport::TestCase
  test 'event registration confirmation' do
    event_registration = build_event_registration()
    event_registration.event.update!(rich_text_confirmation_email: "<p>Test Content</p>")
    event_registration.ready!

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

    event_registrant = event_registration.event_registrants.last

    assert_email(count: 2) { event_registrant.send_order_emails! }

    email = ActionMailer::Base.deliveries.last
    assert email.body.include?("<p>Test Content</p>")
  end

end
