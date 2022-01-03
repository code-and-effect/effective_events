module Admin
  class EventsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    submit :save, 'Save'
    submit :save, 'Save and Add New', redirect: :new
    submit :save, 'Save and View', redirect: -> { effective_events.event_path(resource) }
    submit :save, 'Duplicate', redirect: -> { effective_events.new_admin_event_path(duplicate_id: resource.id) }

    def post_params
      params.require(:effective_event).permit!
    end

  end
end
