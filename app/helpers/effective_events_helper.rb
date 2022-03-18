module EffectiveEventsHelper

  def effective_events_event_tickets_collection(event, namespace = nil)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    # Allow an admin to assign archived tickets
    authorized = (namespace == :admin)
    tickets = (authorized ? event.event_tickets : event.event_tickets.reject(&:archived?))

    tickets.map do |ticket|
      title = ticket.to_s
      price = (ticket.price == 0 ? '$0' : price_to_currency(ticket.price))
      remaining = (ticket.capacity.present? ? "#{ticket.capacity_available} remaining" : nil)

      label = [title, price, remaining].compact.join(' - ')
      disabled = { disabled: :disabled } unless (authorized || ticket.available?)

      [label, ticket.to_param, disabled].compact
    end
  end

  def effective_events_event_products_collection(event, namespace = nil)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    # Allow an admin to assign archived products
    authorized = (namespace == :admin)
    products = (authorized ? event.event_products : event.event_products.reject(&:archived?))

    products.map do |product|
      title = product.to_s
      price = (product.price == 0 ? '$0' : price_to_currency(product.price))
      remaining = (product.capacity.present? ? "#{product.capacity_available} remaining" : nil)

      label = [title, price, remaining].compact.join(' - ')
      disabled = { disabled: :disabled } unless (authorized || product.available?)

      [label, product.to_param, disabled].compact
    end
  end

end
