module Admin
  class EffectiveEventAddonsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :purchased
      scope :deferred
      scope :not_purchased
      scope :archived
    end

    datatable do
      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false
      col :archived, visible: false

      col :event

      col :event_registration, visible: false

      if attributes[:event_id]
        col :event_product, search: Effective::EventProduct.where(event: event).all
      else
        col :event_product, search: :string
      end

      col :purchased_order, visible: false
      col :owner, visible: false

      col :first_name
      col :last_name
      col :email
      col :notes, label: 'Notes'

      actions_col
    end

    collection do
      scope = Effective::EventAddon.deep.registered.includes(:purchased_order, :owner)

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
