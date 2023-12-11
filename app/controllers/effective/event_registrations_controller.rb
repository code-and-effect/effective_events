module Effective
  class EventRegistrationsController < ApplicationController
    if defined?(Devise)
      before_action :authenticate_user!, unless: -> { action_name == 'new' || (action_name == 'show' && params[:id] == 'start') }
    end

    include Effective::WizardController

    before_action :redirect_unless_registerable, only: [:new, :show]

    resource_scope -> {
      event = Effective::Event.find(params[:event_id])
      EffectiveEvents.EventRegistration.deep.where(owner: current_user, event: event)
    }

    # Override ready_checkout to also check for any currently sold out tickets or addons
    # Prevents people from coming back and purchasing them
    def ready_checkout
      return unless step == :checkout
      return unless resource.class.try(:acts_as_purchasable_wizard?)

      if resource.sold_out_event_registrants.present? || resource.sold_out_event_addons.present?
        flash[:danger] = "Your selected event tickets are sold out. This event registration is no longer available."
        return redirect_to('/dashboard')
      end

      resource.ready!
    end

    # If the event is no longer registerable, do not let them continue
    def redirect_unless_registerable
      return if resource.blank?
      return if resource.event.blank?
      return if resource.event.registerable?

      flash[:danger] = "Your selected event is no longer available for registration. This event registration is no longer available."
      return redirect_to('/dashboard')
    end

  end
end
