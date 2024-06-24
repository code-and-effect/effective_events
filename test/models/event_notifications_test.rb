require 'test_helper'

class EventNotificationsTest < ActiveSupport::TestCase
  test 'is valid' do
    event_notification = build_event_notification
    assert event_notification.valid?
  end

  test 'notify!' do
    event = build_event()
    event.save!

    event_registrant = build_event_registrant(event: event)
    event_registrant.save!

    event_notification = build_event_notification(event: event)
    event_notification.save!

    assert_email(count: 1) do
      event_notification.notify!(event_registrants: [event_registrant])
    end

    email = ActionMailer::Base.deliveries.last

    assert_equal email.from, [event_notification.from]
    assert_equal email.subject, event_notification.subject
    assert_equal email.body, event_notification.body
  end

  test 'notify! with liquid' do
    event = build_event()
    event.save!

    event_registrant = build_event_registrant(event: event)
    event_registrant.save!

    event_notification = build_event_notification(event: event)
    event_notification.save!

    event_notification.update!(subject: "Cool subject {{ event.name }}", body: "Cool body {{ event.name }} {{ registrant.name }} {{ ticket.name }}")

    assert_email(count: 1) do
      event_notification.notify!(event_registrants: [event_registrant])
    end

    email = ActionMailer::Base.deliveries.last

    assert_equal email.from, [event_notification.from]
    assert_equal email.subject, "Cool subject #{event.title}"
    assert_equal email.body, "Cool body #{event.title} #{event_registrant.name} #{event_registrant.event_ticket.title}"
  end

  test 'notification validates liquid body' do
    notification = Effective::EventNotification.new
    refute notification.update(body: "Something {{ busted }", subject: "Also {{ busted }")

    assert notification.errors[:body].present?
    assert notification.errors[:subject].present?
  end

  test 'sends order receipt emails on event registration purchase' do
    event_registration = build_event_registration()

    event_registration.ready!
    order = event_registration.submit_order

    assert_email(count: 2) { order.purchase! }
  end

  test 'notify! with html content' do
    event = build_event()
    event.save!

    event_registrant = build_event_registrant(event: event)
    event_registrant.save!

    email_template = Effective::EmailTemplate.where(template_name: :event_registrant_purchased).first!
    email_template.save_as_html!

    event_notification = build_event_notification(event: event)
    event_notification.save!

    event_notification.update!(subject: "Cool subject {{ event.name }}", body: "<p>Cool body {{ event.name }} {{ registrant.name }}</p>", content_type: 'text/html')

    assert_email(subject: "Cool subject #{event.title}", body: "<p>Cool body #{event.title} #{event_registrant.name}</p>", html_layout: true) do
      event_notification.notify!(event_registrants: [event_registrant])
    end
  end

end
