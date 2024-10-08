module EffectiveEventsHelper

  # Events
  def events_name_label
    et('effective_events.name')
  end

  # Event
  def event_label
    et(Effective::Event)
  end

  # Events
  def events_label
    ets(Effective::Event)
  end

  def effective_events_event_schedule(event)
    if event.start_at.beginning_of_day == event.end_at.beginning_of_day
      "#{event.start_at.strftime("%A, %B %d, %Y · %l:%M%P")} - #{event.end_at.strftime("%l:%M%P")}"
    else
      "#{event.start_at.strftime("%A, %B %d, %Y")} - #{event.end_at.strftime("%A, %B %d, %Y")}"
    end
  end

  def effective_events_ticket_price(event, ticket)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)
    raise('expected an Effective::EventTicket') unless ticket.kind_of?(Effective::EventTicket)

    prices = [
      (ticket.early_bird_price if event.early_bird?), 
      (ticket.regular_price if ticket.regular? || ticket.member_or_non_member?),
      (ticket.member_price if ticket.member_only? || ticket.member_or_non_member?)
    ].compact.sort.uniq

    if prices.length > 1
      "#{(prices.first == 0 ? '$0' : price_to_currency(prices.first))} or #{(prices.last == 0 ? '$0' : price_to_currency(prices.last))}"
    else
      (prices.first == 0 ? '$0' : price_to_currency(prices.first))
    end
  end

  def effective_events_event_tickets_collection(event, namespace = nil)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    # Allow an admin to assign archived tickets
    authorized = (namespace == :admin)
    member = current_user.try(:membership_present?)

    tickets = (authorized ? event.event_tickets : event.event_tickets.reject(&:archived?))
    tickets = tickets.reject { |ticket| ticket.member_only? } unless (authorized || member)

    tickets.map do |ticket|
      title = ticket.to_s
      title = "#{title} (archived)" if ticket.archived?

      price = effective_events_ticket_price(event, ticket)

      label = [title, price].compact.join(' - ')

      disabled = { disabled: :disabled } unless (authorized || ticket.waitlist? || event.event_ticket_available?(ticket, quantity: 1))

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
