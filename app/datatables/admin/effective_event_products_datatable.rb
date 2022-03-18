module Admin
  class EffectiveEventProductsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :archived
    end

    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      col :title
      col :price, as: :price

      col :capacity_to_s, label: 'Capacity' do |ticket|
        if ticket.capacity.present?
          "#{ticket.capacity_available} remaining / #{ticket.capacity} total"
        end
      end

      col :purchased_event_addons_count, label: 'Purchased'
      col :capacity, visible: false
      col :capacity_available, visible: false

      col :purchased_event_addons, label: 'Purchased by' do |product|
        product.purchased_event_addons.sort_by(&:to_s).map do |purchase|
          content_tag(:div, purchase.owner.to_s, class: 'col-resource_item')
        end.join.html_safe
      end

      actions_col
    end

    collection do
      scope = Effective::EventProduct.deep.all

      if attributes[:event_id]
        scope = scope.where(event: event)
      end

      scope
    end

    def event
      Effective::Event.find(attributes[:event_id])
    end
  end
end
