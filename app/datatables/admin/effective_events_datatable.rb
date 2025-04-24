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
      order :start_at

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :start_at, label: 'Date'
      col :end_at, label: 'End Date', visible: false

      col :title do |event|
        link_to event.title, effective_events.edit_admin_event_path(event)
      end

      col :slug, visible: false

      col :draft?, as: :boolean, visible: false
      col :published?, as: :boolean
      col :published_start_at, label: "Published start", as: :datetime
      col :published_end_at, label: "Published end", as: :datetime

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

      col :delayed_payment, visible: false
      col :delayed_payment_date, visible: false

      # These show too much information to be useful to admins, rely on the edit screen
      # col :event_tickets
      # col :event_products
      # col :event_registrants
      # col :event_addons

      col :allow_blank_registrants, visible: false
      col :roles, visible: false
      col :authenticate_user, visible: false

      col :qb_item_names, 
        search: { fuzzy: true, collection: Effective::ItemName.sorted.map(&:to_s) },
        label: qb_item_names_label,
        visible: false do |event|
          event.qb_item_names.map { |qb_item_name| content_tag(:div, qb_item_name) } .join.html_safe
      end

      actions_col do |event|
        dropdown_link_to('View Event', effective_events.event_path(event), target: '_blank')
      end
    end

    collection do
      Effective::Event.deep.all
    end

  end
end
