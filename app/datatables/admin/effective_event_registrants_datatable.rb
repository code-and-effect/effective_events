module Admin
  class EffectiveEventRegistrantsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :archived
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      col :owner, visible: false
      col :event_registration, visible: false

      if attributes[:event_id]
        col :event_ticket, search: Effective::EventTicket.where(event: event).all
      else
        col :event_ticket, search: :string
      end

      col :purchased_order, visible: false

      col :first_name
      col :last_name
      col :email
      col :company
      col :number, label: 'Designations'
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
      @event ||= if attributes[:event_id]
        Effective::Event.find_by_id(attributes[:event_id])
      end
    end
  end
end
