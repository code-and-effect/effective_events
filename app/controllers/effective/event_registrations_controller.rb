module Effective
  class EventRegistrationsController < ApplicationController
    if defined?(Devise)
      before_action :authenticate_user!, unless: -> { action_name == 'new' || (action_name == 'show' && params[:id] == 'start') }
    end

    include Effective::WizardController

    before_action :redirect_unless_registerable, only: [:new, :show]
    before_action :expire_ticket_selection_window, only: [:show]

    resource_scope -> {
      event = Effective::Event.find(params[:event_id])
      EffectiveEvents.EventRegistration.deep.where(owner: current_user, event: event)
    }

    # If the event is no longer registerable, do not let them continue
    def redirect_unless_registerable
      return if resource.blank?
      return if resource.was_submitted?
      return if resource.event.blank?
      return if resource.submit_order&.deferred?
      return if resource.event.registerable? && !resource.event.sold_out?(except: resource)

      flash[:danger] = "Your selected event is no longer available for registration. This event registration is no longer available."
      return redirect_to('/dashboard')
    end

    def expire_ticket_selection_window
      return if resource.blank?
      return if resource.was_submitted?
      return if resource.event.blank?
      return if resource.selection_not_expired?

      resource.ticket_selection_expired!

      flash[:danger] = "Your ticket reservation window has expired. Your tickets are no longer reserved. Please start over."

      return redirect_to(wizard_path(:start))
    end

    # TODO: Add better permitted params

  end
end
