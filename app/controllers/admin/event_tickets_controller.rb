module Admin
  class EventTicketsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    datatable -> { Admin::EffectiveEventTicketsDatatable.new }
  end
end
