module Effective
  class EventsController < ApplicationController
    include Effective::CrudController

    resource_scope -> {
      unpublished = EffectiveResources.authorized?(self, :admin, :effective_events)
      Effective::Event.events(user: current_user, unpublished: unpublished)
    }

    def index
      EffectiveResources.authorize!(self, :index, Effective::Event)

      # Page Title
      if event_category.blank?
        @page_title = "Upcoming #{EffectiveResources.ets(Effective::Event)}"
      elsif event_category == 'past'
        @page_title = "Past #{EffectiveResources.ets(Effective::Event)}"
      elsif event_category.present?
        @page_title = event_category
        @event_category = event_category
      else
        @page_title = view_context.events_name_label
      end

      # Sometimes we just display a Datatable for the events
      @datatable = EffectiveResources.best('EffectiveEventsDatatable').new

      # But more often we do a full paginated index with search screen
      @event_search = build_event_search
      @event_search.search!

      @events = @event_search.results(page: params[:page])
    end

    def show
      @event = resource_scope.find(params[:id])
      @upcoming_events = resource_scope.upcoming.where.not(id: @event.id)

      EffectiveResources.authorize!(self, :show, @event)

      if EffectiveResources.authorized?(self, :admin, :effective_events)
        flash.now[:warning] = [
          'Hi Admin!',
          ('You are viewing a hidden event. ' if @event.draft?),
          ("<a href='#{effective_events.edit_admin_event_path(@event)}' class='alert-link'>Edit this event</a>.")
        ].compact.join(' ')
      end

      @page_title ||= @event.to_s
    end

    def build_event_search
      search = EventSearch.new(search_params)
      search.current_user = current_user
      search.unpublished = EffectiveResources.authorized?(self, :admin, :effective_events)
      search.category ||= event_category
      search
    end

    def event_category
      return nil unless params[:category].present?
      (Array(EffectiveEvents.categories) + ['past']).find { |category| category.parameterize == params[:category] }
    end

    def search_params
      return {} unless params[:q].present?

      if params[:q].respond_to?(:to_h)      # From the search form
        params.require(:q).permit!
      else
        { term: params.permit(:q).fetch(:q) }   # From the url /events?q=asdf
      end
    end

  end
end
