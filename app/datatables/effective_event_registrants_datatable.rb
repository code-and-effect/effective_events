# Used on the Event Registrations tickets step

class EffectiveEventRegistrantsDatatable < Effective::Datatable
  datatable do
    order :id

    col :full_name, label: 'Name'
    col :id, visible: false

    col :event_ticket, label: 'Ticket' do |er|
      [er.event_ticket.to_s, er.details.presence].compact.join('<br>').html_safe
    end

    col :user, label: 'Member', visible: false
    col :organization, visible: false

    col :first_name, visible: false
    col :last_name, visible: false
    col :email, visible: false
    col :company, visible: false

    col :response1, visible: false
    col :response2, visible: false
    col :response3, visible: false

    col :responses, label: 'Details'

    col :price, as: :price
    col :archived, visible: false

    # no actions_col
  end

  collection do
    scope = Effective::EventRegistrant.deep.all

    if event.present?
      scope = scope.where(event: event)
    end

    if event_registration.present?
      scope = scope.where(event_registration_id: event_registration).sorted
    end

    scope
  end

  def event
    @event ||= if attributes[:event_id]
      Effective::Event.find_by_id(attributes[:event_id])
    end
  end

  def event_registration
    @event_registration ||= if attributes[:event_registration_id]
      EffectiveEvents.EventRegistration.find_by_id(attributes[:event_registration_id])
    end
  end

end
