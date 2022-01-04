module Admin
  class EffectiveEventRegistrantsDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event_ticket, search: { collection: Effective::EventTicket.where(event: event).all }
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
      Effective::EventRegistrant.deep.purchased.where(event: event)
    end

    def event
      Effective::Event.find(attributes[:event_id])
    end
  end
end
