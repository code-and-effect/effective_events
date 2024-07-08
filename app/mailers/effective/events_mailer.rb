module Effective
  class EventsMailer < EffectiveEvents.parent_mailer_class

    include EffectiveMailer
    include EffectiveEmailTemplatesMailer

    def event_registrant_purchased(resource, opts = {})
      raise('expected an Effective::EventRegistrant') unless resource.kind_of?(Effective::EventRegistrant)

      @assigns = assigns_for(resource)
      mail(to: resource.member_email, **headers_for(resource, opts))
    end

    protected

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
