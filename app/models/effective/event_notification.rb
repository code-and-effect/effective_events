module Effective
  class EventNotification < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_notifications_table_name || :event_notifications).to_s

    acts_as_email_notification # effective_resources
    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event

    CATEGORIES = ['Registrant purchased']
    EMAIL_TEMPLATE_VARIABLES = ['event.name', 'event.date', 'event.url', 'ticket.name', 'registrant.name', 'registrant.email']

    #CATEGORIES = ['Upcoming reminder', 'When event starts', 'Reminder', 'Before event ends', 'When event ends']

    # UPCOMING_REMINDERS = {
    #   '1 hour before' => 1.hours.to_i,
    #   '3 hours before' => 3.hours.to_i,
    #   '6 hours before' => 6.hours.to_i,
    #   '12 hours before' => 12.hours.to_i,
    #   '1 day before' => 1.days.to_i,
    #   '2 days before' => 2.days.to_i,
    #   '3 days before' => 3.days.to_i,
    #   '4 days before' => 4.days.to_i,
    #   '5 days before' => 5.days.to_i,
    #   '6 days before' => 6.days.to_i,
    #   '1 week before' => 1.weeks.to_i,
    #   '2 weeks before' => 2.weeks.to_i,
    #   '3 weeks before' => 3.weeks.to_i,
    #   '1 month before' => 1.month.to_i
    # }

    # REMINDERS = {
    #   '1 hour after' => 1.hours.to_i,
    #   '3 hours after' => 3.hours.to_i,
    #   '6 hours after' => 6.hours.to_i,
    #   '12 hours after' => 12.hours.to_i,
    #   '1 day after' => 1.days.to_i,
    #   '2 days after' => 2.days.to_i,
    #   '3 days after' => 3.days.to_i,
    #   '4 days after' => 4.days.to_i,
    #   '5 days after' => 5.days.to_i,
    #   '6 days after' => 6.days.to_i,
    #   '1 week after' => 1.weeks.to_i,
    #   '2 weeks after' => 2.weeks.to_i,
    #   '3 weeks after' => 3.weeks.to_i,
    #   '1 month after' => 1.month.to_i
    # }

    effective_resource do
      category          :string
      reminder          :integer  # Number of seconds before event.start_at

      # Email
      from              :string
      subject           :string
      body              :text

      cc                :string
      bcc               :string
      content_type      :string

      # Tracking background jobs email send out
      started_at        :datetime
      completed_at      :datetime

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:event) }

    scope :started, -> { where.not(started_at: nil) }
    scope :completed, -> { where.not(completed_at: nil) }

    # Called by a future event_notifier rake task
    scope :notifiable, -> { where(started_at: nil, completed_at: nil) }

    validates :category, presence: true, inclusion: { in: CATEGORIES }

    # validates :reminder, if: -> { reminder? || upcoming_reminder? || before_event_ends? },
    #   presence: true, uniqueness: { scope: [:event_id, :category], message: 'already exists' }

    def to_s
      'event notification'
    end

    def email_template
      'event_' + category.to_s.parameterize.underscore
    end

    def email_template_variables
      EMAIL_TEMPLATE_VARIABLES
    end

    def registrant_purchased?
      category == 'Registrant purchased'
    end

    # def upcoming_reminder?
    #   category == 'Upcoming reminder'
    # end

    # def event_start?
    #   category == 'When event starts'
    # end

    # def reminder?
    #   category == 'Reminder'
    # end

    # def before_event_ends?
    #   category == 'Before event ends'
    # end

    # def event_end?
    #   category == 'When event ends'
    # end

    # def notifiable?
    #   started_at.blank? && completed_at.blank?
    # end

    def notify_now?
      true

      #return false unless notifiable?

      # case category
      # when 'When event starts'
      #   event.available?
      # when 'When event ends'
      #   event.ended?
      # when 'Upcoming reminder'
      #   !event.started? && event.start_at < (Time.zone.now + reminder)
      # when 'Reminder'
      #   !event.ended? && event.start_at < (Time.zone.now - reminder)
      # when 'Before event ends'
      #   !event.ended? && event.end_at.present? && event.end_at < (Time.zone.now + reminder)
      # else
      #   raise('unexpected category')
      # end
    end

    def notify!(force: false, event_registrants: nil)
      return false unless (notify_now? || force)

      # We send one email to each registrant
      event_registrants ||= event.event_registrants.purchased

      update_column(:started_at, Time.zone.now)

      event_registrants.each do |event_registrant|
        next if event_registrant.email.blank?

        begin
          EffectiveEvents.send_email(email_template, event_registrant, email_notification_params)
        rescue => e
          EffectiveLogger.error(e.message, associated: event_registrant) if defined?(EffectiveLogger)
          EffectiveResources.send_error(e, event_registrant_id: event_registrant.id, event_notification_id: id)
          raise(e) if Rails.env.test? || Rails.env.development?
        end
      end

      update_column(:completed_at, Time.zone.now)
    end

  end
end
