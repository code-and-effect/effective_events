module Admin
  class EffectiveEventsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :registerable
      scope :drafts
      scope :upcoming
      scope :past
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :start_at, label: 'Event Date'

      col :end_at, visible: false
      col :excerpt, visible: false

      col :registration_start_at, label: 'Registration opens'
      col :registration_end_at, label: 'Registration closes'
      col :early_bird_end_at, label: 'Early bird ends'

      col :early_bird do |event|
        if event.early_bird?
          content_tag(:span, event.early_bird_status, class: 'badge badge-success')
        else
          event.early_bird_status
        end
      end

      col :event_tickets, search: :string
      col :event_registrants, search: :string

      col :draft
      col :roles, visible: false
      col :authenticate_user, visible: false

      actions_col
    end

    collection do
      Effective::Event.deep.all
    end

  end
end
