module Effective
  class EventsMailer < EffectiveEvents.parent_mailer_class

    include EffectiveMailer
    include EffectiveEmailTemplatesMailer

    helper EffectiveEventsHelper
    helper EffectiveOrdersHelper

    # For the notifications. No longer used.
    def event_registrant_purchased(resource, opts = {})
      raise('expected an Effective::EventRegistrant') unless resource.kind_of?(Effective::EventRegistrant)

      @assigns = assigns_for(resource)
      mail(to: resource.email, **headers_for(resource, opts))
    end

    # Sent on registration purchase
    # Sent on delayed payment date registration submitted
    # Sent on delayed payment date registration update 
    # Sent on update blank registrants
    def event_registration_confirmation(resource, opts = {})
      raise('expected an event registration') unless resource.class.try(:effective_events_event_registration?)

      @event_registration = resource
      @event = resource.event

      @order = @event_registration.submit_order
      raise('expected an event registration submit_order') unless @order.present?

      subject = subject_for(__method__, "Event Confirmation - #{@event}", resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.owner.email, subject: subject, **headers)
    end

    # Sent manually by an admin to one registrant
    def event_registrant_confirmation(resource, opts = {})
      raise('expected an event registrant') unless resource.kind_of?(Effective::EventRegistrant)

      @event_registrant = resource
      @event = resource.event
      @event_registration = resource.event_registration # Optional

      subject = subject_for(__method__, "Event Registrant Confirmation - #{@event}", resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.email, subject: subject, **headers)
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
