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
      col :regular_price, as: :price
      col :early_bird_price, as: :price

      col :capacity_to_s, label: 'Capacity' do |ticket|
        if ticket.capacity.present?
          "#{ticket.capacity_available} remaining / #{ticket.capacity} total"
        end
      end

      col :registered_event_registrants_count, label: 'Registered' do |event|
        event.event_registrants.registered.unarchived.count
      end

      col :purchased_event_registrants_count, label: 'Purchased', visible: false do |event|
        event.event_registrants.purchased.unarchived.count
      end

      col :capacity, visible: false
      col :capacity_available, visible: false

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
