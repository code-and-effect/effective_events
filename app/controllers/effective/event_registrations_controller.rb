module Effective
  class EventRegistrationsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> {
      event = Effective::Event.find(params[:event_id])
      EffectiveEvents.EventRegistration.deep.where(owner: current_user, event: event)
    }

    # Allow only 1 in-progress event registration at a time
    before_action(only: [:new, :show], unless: -> { resource&.done? }) do
      existing = resource_scope.in_progress.where.not(id: resource).first

      if existing.present?
        flash[:success] = "You have been redirected to your existing in progress event registration"
        redirect_to effective_events.event_event_registration_build_path(existing.event, existing, existing.next_step)
      end
    end

    after_save do
      flash.now[:success] = ''
    end

    # The default redirect doesn't respect nested resources here
    def new
      self.resource ||= (find_wizard_resource || resource_scope.new)
      EffectiveResources.authorize!(self, :new, resource)

      redirect_to effective_events.event_event_registration_build_path(
        resource.event,
        (resource.to_param || :new),
        (resource.first_uncompleted_step || resource_wizard_steps.first)
      )
    end

    private

    def permitted_params
      model = (params.key?(:effective_event_registration) ? :effective_event_registration : :event_registration)

      params.require(model).permit!.except(:status, :status_steps, :wizard_steps, :submitted_at)
    end

  end
end
