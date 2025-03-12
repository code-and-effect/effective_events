module Admin
  class EventRegistrantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    submit :mark_registered, 'Save and Mark Registered'
    submit :save_and_update_orders, 'Save and Update Orders'

  end
end
