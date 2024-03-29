module EffectiveEventsHelper
  def effective_events_event_schedule(event)
    if event.start_at.beginning_of_day == event.end_at.beginning_of_day
      "#{event.start_at.strftime("%b %d, %Y %I:%M%P")} - #{event.end_at.strftime("%I:%M%P")}"
    else
      "#{event.start_at.strftime("%b %d, %Y")} - #{event.end_at.strftime("%b %d, %Y")}"
    end
  end

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
      disabled = { disabled: :disabled } unless (authorized || event.event_ticket_available?(ticket, quantity: 1))

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
      disabled = { disabled: :disabled } unless (authorized || event.event_product_available?(product, quantity: 1))

      [label, product.to_param, disabled].compact
    end
  end
end
