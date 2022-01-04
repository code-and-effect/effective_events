module Admin
  class EffectiveEventRegistrantsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      if attributes[:event_id]
        col :event_ticket, search: Effective::EventTicket.where(event: event).all
      else
        col :event_ticket, search: :string
      end

      col :purchased_order

      col :first_name
      col :last_name
      col :email
      col :company
      col :number
      col :notes, label: 'Restrictions and notes'

      actions_col
    end

    collection do
      scope = Effective::EventRegistrant.deep.purchased

      if attributes[:event_id].present?
        scope = scope.where(event: event)
      end

      scope
    end

    def event
      @event ||= if attributes[:event]
        Effective::Event.find(attributes[:event_id])
      end
    end
  end
end
