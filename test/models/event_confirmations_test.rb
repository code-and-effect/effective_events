require 'test_helper'

class EventConfirmationsTest < ActiveSupport::TestCase
  test 'event registration confirmation' do
    event_registration = build_event_registration()
    event_registration.event.update!(rich_text_confirmation_email: "<p>Test Content</p>")

    assert_email(count: 1) do
      event_registration.send_event_registration_confirmation!
    end

    email = ActionMailer::Base.deliveries.last
    assert email.body.include?("<p>Test Content</p>")
  end

  test 'event registrant confirmation' do
    event = build_event()
    event_registration = build_event_registration(event: event)
    event_registration.event.update!(rich_text_confirmation_email: "<p>Test Content</p>")

    event_registrant = event_registration.event_registrants.last

    assert_email { event_registrant.send_confirmation_email! }

    email = ActionMailer::Base.deliveries.last
    assert email.body.include?("<p>Test Content</p>")
  end

end
