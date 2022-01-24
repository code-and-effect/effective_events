module Effective
  class EventsController < ApplicationController
    include Effective::CrudController

    resource_scope -> {
      unpublished = EffectiveResources.authorized?(self, :admin, :effective_events)
      Effective::Event.events(user: current_user, unpublished: unpublished)
    }

    def show
      @event = resource_scope.find(params[:id])

      if @event.respond_to?(:roles_permit?)
        raise Effective::AccessDenied.new('Access Denied', :show, @event) unless @event.roles_permit?(current_user)
      end

      EffectiveResources.authorize!(self, :show, @event)

      if EffectiveResources.authorized?(self, :admin, :effective_events)
        flash.now[:warning] = [
          'Hi Admin!',
          ('You are viewing a hidden event.' if @event.draft?),
          'Click here to',
          ("<a href='#{effective_events.edit_admin_event_path(@event)}' class='alert-link'>edit event settings</a>.")
        ].compact.join(' ')
      end

      @page_title ||= @event.to_s
    end

  end
end
