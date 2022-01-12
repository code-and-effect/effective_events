module EffectiveEventsHelper

  def effective_events_event_tickets_collection(event)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    event.event_tickets.map do |ticket|
      label = ticket.to_s
      price = (ticket.price == 0 ? '$0' : price_to_currency(ticket.price))

      ["#{label} - #{price}", ticket.to_param]
    end
  end

  def effective_events_event_products_collection(event)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    event.event_products.map do |product|
      label = product.to_s
      price = (product.price == 0 ? '$0' : price_to_currency(product.price))

      ["#{label} - #{price}", product.to_param]
    end
  end

  def edit_effective_event_registrations_wizard?
    params[:controller] == 'effective/event_registrations' && defined?(resource) && resource.draft?
  end

end
