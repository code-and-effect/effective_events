module Admin
  class EventRegistrantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    datatable -> { Admin::EffectiveEventRegistrantsDatatable.new }
  end
end
