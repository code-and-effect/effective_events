module Admin
  class EventRegistrationsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    resource_scope -> { EffectiveEvents.EventRegistration.deep.all }
    datatable -> { Admin::EffectiveEventRegistrationsDatatable.new }

    private

    def permitted_params
      model = (params.key?(:effective_event_registration) ? :effective_event_registration : :event_registration)
      params.require(model).permit!
    end

  end
end
