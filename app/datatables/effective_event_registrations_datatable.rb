# Dashboard Event Registrations
class EffectiveEventRegistrationsDatatable < Effective::Datatable
  datatable do
    order :created_at

    col :token, visible: false
    col :created_at, visible: false

    col(:submitted_at, label: 'Registered on') do |er|
      er.submitted_at&.strftime('%F') || 'Incomplete'
    end

    col :event, search: :string do |er|
      er.event.to_s
    end

    col :owner, visible: false, search: :string
    col :status, visible: false
    col :event_registrants, label: 'Registrants', search: :string
    col :event_purchases, label: 'Purchases', search: :string
    col :orders, action: :show, visible: false, search: :string

    actions_col(actions: []) do |er|
      if er.draft?
        dropdown_link_to('Continue', effective_events.event_event_registration_build_path(er.event, er, er.next_step), 'data-turbolinks' => false)
        dropdown_link_to('Delete', effective_events.event_event_registration_path(er.event, er), 'data-confirm': "Really delete #{er}?", 'data-method': :delete)
      else
        dropdown_link_to('Show', effective_events.event_event_registration_path(er.event, er))
      end
    end
  end

  collection do
    EffectiveEvents.EventRegistration.deep.where(owner: current_user)
  end

end
