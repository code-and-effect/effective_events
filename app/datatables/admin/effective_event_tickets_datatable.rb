module Admin
  class EffectiveEventTicketsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :title
      col :regular_price, as: :price
      col :early_bird_price, as: :price
      col :capacity
      col :event_registrants_count

      actions_col
    end

    collection do
      Effective::EventTicket.deep.all.where(event: event)
    end

    def event
      Effective::Event.find(attributes[:event_id])
    end
  end
end
