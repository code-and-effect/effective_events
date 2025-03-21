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
      col :archived, visible: false

      col :event

      col :title
      col :price, as: :price

      col :capacity_to_s, label: 'Capacity' do |ticket|
        if ticket.capacity.present?
          "#{ticket.capacity_available} remaining / #{ticket.capacity} total"
        end
      end

      col :registered_event_addons_count, label: 'Registered'
      col :purchased_event_addons_count, label: 'Purchased', visible: false

      col :capacity, visible: false
      col :capacity_available, visible: false

      # col :registered_event_addons, label: 'Registered Names' do |product|
      #   product.registered_event_addons.reject(&:archived?).sort_by(&:to_s).map do |addon|
      #     content_tag(:div, addon.name.to_s, class: 'col-resource_item')
      #   end.join.html_safe
      # end

      # col :purchased_event_addons, label: 'Purchased Names', visible: false do |product|
      #   product.purchased_event_addons.reject(&:archived?).sort_by(&:to_s).map do |addon|
      #     content_tag(:div, addon.name.to_s, class: 'col-resource_item')
      #   end.join.html_safe
      # end

      col :qb_item_name, label: qb_item_name_label, search: Effective::ItemName.sorted.map(&:to_s), visible: false

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
      Effective::Event.find_by_id(attributes[:event_id])
    end
  end
end
