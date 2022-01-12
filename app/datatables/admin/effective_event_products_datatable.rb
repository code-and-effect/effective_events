module Admin
  class EffectiveEventProductsDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      col :title
      col :price, as: :price

      #col :capacity
      col :purchased_event_purchases_count, label: 'Purchased'

      col :purchased_event_purchases, label: 'Purchased by' do |product|
        product.purchased_event_purchases.sort_by(&:to_s).map do |purchase|
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
