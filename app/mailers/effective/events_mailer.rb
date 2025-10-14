module Effective
  class EventsMailer < EffectiveEvents.parent_mailer_class

    include EffectiveMailer
    include EffectiveEmailTemplatesMailer

    helper EffectiveEventsHelper
    helper EffectiveOrdersHelper

    # We do not send email from this gem, and instead use the effective_orders gem to send the email.

    def event_capacity_released(resource, opts = {})
      raise('expected an event_registration') unless resource.class.try(:effective_events_event_registration?)

      @assigns = assigns_for(resource)

      @event_registration = resource
      @event = @event_registration.event

      mail(to: mailer_admin, **headers_for(resource, opts))
    end

    # For the notifications. No longer used.
    # def event_registrant_purchased(resource, opts = {})
    #   raise('expected an Effective::EventRegistrant') unless resource.kind_of?(Effective::EventRegistrant)

    #   @assigns = assigns_for(resource)
    #   mail(to: resource.email, **headers_for(resource, opts))
    # end

    protected

    def assigns_for(resource)
      if resource.kind_of?(EventRegistrant)
        return event_registrant_assigns(resource).merge(event_assigns(resource.event)).merge(event_ticket_assigns(resource.event_ticket))
      end

      if resource.class.try(:effective_events_event_registration?)
        return event_registration_assigns(resource).merge(event_assigns(resource.event))
      end

      raise('unexpected resource')
    end

    def event_assigns(resource)
      raise('expected an event') unless resource.kind_of?(Event)

      values = {
        name: resource.title,
        date: resource.start_at.strftime('%F %H:%M'),
        url: link_to(effective_events.event_url(resource))
      }

      { 
        event: values,
        dashboard_url: link_to(root_url + 'dashboard')
      }
    end

    def event_registration_assigns(resource)
      raise('expected an event registration') unless resource.class.try(:effective_events_event_registration?)

      values = { 
        owner: resource.owner.to_s, 
        email: resource.email, 
        cancelled_registrants: resource.event_registrants.select(&:cancelled?).map(&:to_s).join("<br>"),
        url: link_to(effective_events.event_event_registration_url(resource.event, resource))
      }

      { event_registration: values }
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
