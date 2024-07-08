module Admin
  class EffectiveEventTicketsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :archived
    end

    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false
      col :archived, visible: false

      col :event

      col :title
      col :category, visible: false

      col :early_bird_price, as: :price, visible: event&.early_bird_end_at.present?
      col :regular_price, as: :price
      col :member_price, as: :price

      col :waitlist
      col :capacity_available, visible: false
      col :capacity, label: 'Capacity Total', visible: false

      col :capacity_to_s, label: 'Capacity' do |ticket|
        if ticket.capacity.present? && ticket.waitlist?
          "#{ticket.capacity_available} remaining / #{ticket.capacity} total. #{ticket.waitlisted_event_registrants_count} waitlisted."
        elsif ticket.capacity.present?
          "#{ticket.capacity_available} remaining / #{ticket.capacity} total"
        end
      end

      col :category, visible: false

      col :registered_event_registrants_count, label: 'Registered' do |event|
        event.event_registrants.registered.unarchived.count
      end

      col :purchased_event_registrants_count, label: 'Deferred', visible: false do |event|
        event.event_registrants.deferred.unarchived.count
      end

      col :purchased_event_registrants_count, label: 'Purchased', visible: false do |event|
        event.event_registrants.purchased.unarchived.count
      end


      col :question1, visible: false
      col :question2, visible: false
      col :question3, visible: false

      actions_col
    end

    collection do
      scope = Effective::EventTicket.deep.all

      if attributes[:event_id]
        scope = scope.where(event: event)
      end

      scope
    end

    def event
      Effective::Event.find_by_id(attributes[:event_id])
    end
  end
end
