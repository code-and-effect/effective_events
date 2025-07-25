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

  def event_status_badge(event)
    event.roles.map do |role|
      content_tag(:span, "#{role.to_s.upcase} ONLY", class: 'badge badge-secondary')
    end.join(' ').html_safe
  end

  def admin_event_status_badge(event)
    return nil unless EffectiveResources.authorized?(self, :admin, :effective_events)

    if event.try(:archived?)
      content_tag(:span, 'ARCHIVED', class: 'badge badge-secondary')
    elsif event.draft?
      content_tag(:span, 'NOT PUBLISHED', class: 'badge badge-danger')
    elsif event.published? == false
      content_tag(:span, "TO BE PUBLISHED AT #{event.published_start_at&.strftime('%F %H:%M') || 'LATER'}", class: 'badge badge-danger')
    end
  end

  def effective_events_event_schedule(event)
    if event.start_at.beginning_of_day == event.end_at.beginning_of_day
      "#{event.start_at.strftime("%A, %B %d, %Y · %l:%M%P")} - #{event.end_at.strftime("%l:%M%P")}"
    else
      "#{event.start_at.strftime("%A, %B %d, %Y")} - #{event.end_at.strftime("%A, %B %d, %Y")}"
    end
  end

  def effective_events_ticket_prices(event, ticket)
    raise('expected an Effective::Event') unless event.kind_of?(Effective::Event)
    raise('expected an Effective::EventTicket') unless ticket.kind_of?(Effective::EventTicket)

    guest_of_member = (ticket.guest_of_member? && (current_user.try(:membership_present?) || current_user.is_any?(:member)))

    prices = if event.early_bird? && ticket.early_bird_price.present?
      [ticket.early_bird_price]
    elsif ticket.members?
      [ticket.member_price, (ticket.guest_of_member_price if guest_of_member)].compact
    elsif ticket.anyone?
      [ticket.member_price, (ticket.guest_of_member_price if guest_of_member), ticket.non_member_price].compact
    end.uniq.sort

    prices.map { |price| price == 0 ? '$0' : price_to_currency(price) }.to_sentence(last_word_connector: ' or ', two_words_connector: ' or ')
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
