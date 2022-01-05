module EffectiveEventsHelper

  def effective_events_event_tickets_collection(event)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    event.event_tickets.map do |ticket|
      label = ticket.to_s
      price = (ticket.price == 0 ? '$0' : number_to_currency(ticket.price / 100))

      ["#{label} - #{price}", ticket.to_param]
    end
  end

  def edit_effective_event_registrations_wizard?
    params[:controller] == 'effective/event_registrations' && defined?(resource) && resource.draft?
  end

end
