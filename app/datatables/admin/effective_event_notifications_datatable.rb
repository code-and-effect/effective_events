class Admin::EffectiveEventNotificationsDatatable < Effective::Datatable
  # filters do
  #   scope :all
  #   scope :started
  #   scope :completed
  # end

  datatable do
    col :updated_at, visible: false
    col :created_at, visible: false
    col :id, visible: false

    col :event
    col :category

    col :from, visible: false do |notification|
      ERB::Util.html_escape_once(notification.from)
    end

    # col :reminder do |poll_notification|
    #   case poll_notification.category
    #   when 'When poll starts'
    #     poll_notification.poll.start_at&.strftime('%F %H:%M')
    #   when 'When poll ends'
    #     poll_notification.poll.end_at&.strftime('%F %H:%M')
    #   when 'Upcoming reminder'
    #     Effective::PollNotification::UPCOMING_REMINDERS.invert[poll_notification.reminder]
    #   when 'Reminder'
    #     Effective::PollNotification::REMINDERS.invert[poll_notification.reminder]
    #   when 'Before poll ends'
    #     Effective::PollNotification::UPCOMING_REMINDERS.invert[poll_notification.reminder]
    #   else
    #     raise('unexpected category')
    #   end
    # end

    col :subject

    col :body do |notification|
      simple_format(notification.body)
    end

    col :cc, visible: false
    col :bcc, visible: false
    col :content_type, visible: false

    col :started_at, visible: false
    col :completed_at

    actions_col
  end

  collection do
    Effective::EventNotification.all.deep
  end
end
