module Admin
  class EffectiveEventsDatatable < Effective::Datatable
    filters do
      scope :all
      scope :registerable
      scope :published
      scope :draft
      scope :upcoming
      scope :past
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title do |event|
        link_to event.title, effective_events.edit_admin_event_path(event)
      end

      col :slug, visible: false

      col :draft?, as: :boolean, visible: false
      col :published?, as: :boolean
      col :published_start_at, as: "Published start"
      col :published_end_at, as: "Published end"

      col :start_at, label: 'Start', visible: false
      col :end_at, label: 'End', visible: false
      col :excerpt, visible: false

      col :registration_start_at, label: 'Registration opens', visible: false
      col :registration_end_at, label: 'Registration closes', visible: false
      col :early_bird_end_at, label: 'Early bird ends', visible: false

      col :early_bird, visible: false do |event|
        if event.early_bird?
          content_tag(:span, event.early_bird_status, class: 'badge badge-success')
        else
          event.early_bird_status
        end
      end

      # These show too much information to be useful to admins, rely on the edit screen
      # col :event_tickets, search: :string
      # col :event_products, search: :string
      # col :event_registrants, search: :string
      # col :event_addons, search: :string

      col :allow_blank_registrants, visible: false
      col :roles, visible: false
      col :authenticate_user, visible: false

      actions_col do |event|
        dropdown_link_to('View Event', effective_events.event_path(event), target: '_blank')
      end
    end

    collection do
      Effective::Event.deep.all
    end

  end
end
