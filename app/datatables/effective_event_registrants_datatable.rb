# Used on the Event Registrations tickets step

class EffectiveEventRegistrantsDatatable < Effective::Datatable
  datatable do
    order :id

    col :name do |er|
      if er.first_name.present?
        email = (er.user.present? ? masked_email(er.user) : er.email)
        "#{er.first_name} #{er.last_name}<br><small>#{email}</small>"
      elsif er.owner.present?
        er.owner.to_s + ' - GUEST'
      else
        'Unknown'
      end
    end

    col :id, visible: false

    col :event_ticket, search: :string, label: 'Ticket' do |er|
      [
        er.event_ticket.to_s,
        (content_tag(:span, 'Waitlist', class: 'badge badge-warning') if er.waitlisted_not_promoted?),
        (content_tag(:span, 'Archived', class: 'badge badge-warning') if er.event_ticket&.archived?)
      ].compact.join('<br>').html_safe
    end

    col :user, label: 'Member', visible: false
    col :first_name, visible: false
    col :last_name, visible: false
    col :email, visible: false
    col :company, visible: false

    col :response1, visible: false
    col :response2, visible: false
    col :response3, visible: false

    col :details do |registrant|
      [registrant.response1.presence, registrant.response2.presence, registrant.response3.presence].compact.map do |response|
        content_tag(:div, response)
      end.join.html_safe
    end

    # This is the non-waitlisted full price
    col :event_ticket_price, as: :price, label: 'Price'
    col :archived, visible: false

    # no actions_col
  end

  collection do
    scope = Effective::EventRegistrant.deep.all

    if event.present?
      scope = scope.where(event: event)
    end

    if event_registration.present?
      scope = scope.where(event_registration_id: event_registration)
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
