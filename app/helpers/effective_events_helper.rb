module EffectiveEventsHelper
  def effective_events_event_schedule(event)
    if event.start_at.beginning_of_day == event.end_at.beginning_of_day
      "#{event.start_at.strftime("%b %d, %Y %I:%M%P")} - #{event.end_at.strftime("%I:%M%P")}"
    else
      "#{event.start_at.strftime("%b %d, %Y")} - #{event.end_at.strftime("%b %d, %Y")}"
    end
  end

  def effective_events_ticket_price(event, ticket)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)
    raise('expected an Effective::EventTicket') unless ticket.kind_of?(Effective::EventTicket)

    prices = [
      (ticket.early_bird_price if event.early_bird?), 
      (ticket.member_price unless ticket.non_member?),
      (ticket.regular_price unless ticket.member_only?)
    ].compact.sort.uniq

    if prices.length > 1
      "#{(prices.first == 0 ? '$0' : price_to_currency(prices.first))} to #{(prices.last == 0 ? '$0' : price_to_currency(prices.last))}"
    else
      (prices.first == 0 ? '$0' : price_to_currency(prices.first))
    end
  end

  def effective_events_event_tickets_collection(event, namespace = nil)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)

    # Allow an admin to assign archived tickets
    authorized = (namespace == :admin)
    tickets = (authorized ? event.event_tickets : event.event_tickets.reject(&:archived?))

    tickets.map do |ticket|
      title = ticket.to_s
      price = effective_events_ticket_price(event, ticket)

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

  def effective_events_event_tickets_user_hint
    url = if current_user.class.try(:effective_memberships_organization_user?)
      organization = current_user.membership_organizations.first || current_user.organizations.first
      effective_memberships.edit_organization_path(organization, anchor: 'tab-representatives') if organization
    end || '/dashboard'

    "Can't find the person you need? <a href='#{url}' target='blank'>Click here</a> to add them to your organization."
  end

end
