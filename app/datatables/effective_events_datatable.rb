# Dashboard Events
class EffectiveEventsDatatable < Effective::Datatable
  filters do
    # Upcoming should be first here, so when displayed as a simple datatable on the dashboard they only see upcoming events
    scope :upcoming
    scope :registerable
    scope :external
    scope :all
  end

  datatable do
    order :start_at

    col :id, visible: false

    col :start_at, label: 'Date', as: :date

    col :title, label: 'Title' do |event|
      link_to(event.to_s, effective_events.event_path(event))
    end

    col :registration_start_at, visible: false
    col :registration_end_at, label: 'Registration Closes', visible: false

    col :early_bird, visible: false do |event|
      if event.early_bird?
        content_tag(:span, event.early_bird_status, class: 'badge badge-success')
      else
        event.early_bird_status
      end
    end

    col :event_tickets, visible: false, search: :string
    col :early_bird_end_at, label: 'Early bird ends', visible: false

    actions_col show: false do |event|
      if event.registerable?
        url = event.external_registration_url.presence || effective_events.new_event_event_registration_path(event)
        dropdown_link_to('Register', url)
      end
    end
  end

  collection do
    Effective::Event.deep.events(user: current_user)
  end

end
