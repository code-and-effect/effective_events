module Effective
  class EventsMailer < EffectiveResources.parent_mailer_class
    default from: -> { EffectiveResources.mailer_sender }
    layout -> { EffectiveResources.mailer_layout }

    include EffectiveEmailTemplatesMailer if EffectiveEvents.use_effective_email_templates

    def event_registrant_purchased(event_registrant, opts = {})
      @assigns = assigns_for(event_registrant)
      @event_registrant = event_registrant

      mail(to: event_registrant.email, **headers_for(event_registrant, opts))
    end

    protected

    def headers_for(resource, opts = {})
      resource.respond_to?(:log_changes_datatable) ? opts.merge(log: resource) : opts
    end

    def assigns_for(resource)
      if resource.kind_of?(EventRegistrant)
        return event_registrant_assigns(resource).merge(event_assigns(resource.event)).merge(event_ticket_assigns(resource.event_ticket))
      end

      raise('unexpected resource')
    end

    def event_assigns(resource)
      raise('expected an event') unless resource.kind_of?(Event)

      values = {
        name: resource.title,
        date: resource.start_at.strftime('%F %H:%M'),
        url: effective_events.event_url(resource)
      }

      { event: values }
    end

    def event_ticket_assigns(resource)
      raise('expected an event ticket') unless resource.kind_of?(EventTicket)

      values = { name: resource.title }
      { ticket: values }
    end

    def event_registrant_assigns(resource)
      raise('expected an event registrant') unless resource.kind_of?(EventRegistrant)

      values = { name: resource.name, email: resource.email }
      { registrant: values }
    end

  end
end
