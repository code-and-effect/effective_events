module Effective
  class EventSearch
    include ActiveModel::Model

    ORDERS = ['Sort by Published Date', 'Sort by Event Date']

    attr_accessor :current_user
    attr_accessor :unpublished

    attr_accessor :term
    attr_accessor :category
    attr_accessor :order

    validates :term, length: { minimum: 2, allow_blank: true }
    validates :order, inclusion: { in: ORDERS, allow_blank: true }

    # Base collection to search.
    def collection
      Event.events(user: current_user, unpublished: unpublished)
    end

    def per_page
      (EffectiveEvents.per_page || 24).to_i
    end

    def present?
      term.present? || category.present? || order.present?
    end

    # Search and assigns the collection
    # Assigns the entire collection() if there are no search terms
    # Otherwise validate the search terms
    def search!
      @events = build_collection()
      @events = @events.none if present? && !valid?
      @events
    end

    # The unpaginated results of the search
    def events
      @events || collection
    end

    # The paginated results
    def results(page: nil)
      page = (page || 1).to_i
      offset = [(page - 1), 0].max * per_page

      events.limit(per_page).offset(offset)
    end

    protected

    def build_collection
      events = collection()
      raise('expected an ActiveRecord collection') unless events.kind_of?(ActiveRecord::Relation)

      # Filter by term
      if term.present?
        events = Effective::Resource.new(events).search_any(term)
      end

      # Filter by category
      if category.present?
        events = events.where(category: category)
      end

      # Apply Sorting
      events = case order.to_s
      when 'Sort by Published Date'
        events.reorder(published_at: :desc)
      when 'Sort by Event Date'
        events.reorder(start_at: :desc)
      else
        events.reorder(published_at: :desc) # Default Sort by Published Date
      end

      events
    end
  end

end
