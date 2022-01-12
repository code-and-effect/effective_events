module Admin
  class EffectiveEventPurchasesDatatable < Effective::Datatable
    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      col :event_registration, visible: false

      if attributes[:event_id]
        col :event_product, search: Effective::EventProduct.where(event: event).all
      else
        col :event_product, search: :string
      end

      col :purchased_order
      col :owner
      col :notes, label: 'Notes'

      actions_col
    end

    collection do
      scope = Effective::EventPurchase.deep.purchased

      if attributes[:event_id].present?
        scope = scope.where(event: event)
      end

      scope
    end

    def event
      @event ||= if attributes[:event_id]
        Effective::Event.find(attributes[:event_id])
      end
    end
  end
end
