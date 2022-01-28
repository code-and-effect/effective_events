module EffectiveEventsHelper

  def effective_events_event_tickets_collection(event)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    event.event_tickets.reject(&:archived?).map do |ticket|
      title = ticket.to_s
      price = (ticket.price == 0 ? '$0' : price_to_currency(ticket.price))
      remaining = (ticket.capacity.present? ? "#{ticket.capacity_available} remaining" : nil)

      label = [title, price, remaining].compact.join(' - ')
      disabled = { disabled: :disabled } unless ticket.available?

      [label, ticket.to_param, disabled].compact
    end
  end

  def effective_events_event_products_collection(event)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    event.event_products.reject(&:archived?).map do |product|
      title = product.to_s
      price = (product.price == 0 ? '$0' : price_to_currency(product.price))
      remaining = (product.capacity.present? ? "#{product.capacity_available} remaining" : nil)

      label = [title, price, remaining].compact.join(' - ')
      disabled = { disabled: :disabled } unless product.available?

      [label, product.to_param, disabled].compact
    end
  end

end
