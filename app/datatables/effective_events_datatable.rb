# Dashboard Events
class EffectiveEventsDatatable < Effective::Datatable
  filters do
    # Upcoming should be first here, so when displayed as a simple datatable on the dashboard they only see upcoming events
    scope :registerable
    scope :all
  end

  datatable do
    order :title
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
        dropdown_link_to('Register', effective_events.new_event_event_registration_path(event))
      end
    end
  end

  collection do
    Effective::Event.deep.events(user: current_user)
  end

end
