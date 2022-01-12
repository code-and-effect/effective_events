module Admin
  class EventPurchasesController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_events) }

    include Effective::CrudController

    submit :mark_paid, 'Save and Mark Paid'

  end
end
