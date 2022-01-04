module Admin
  class EffectiveEventTicketsDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :event

      col :title
      col :regular_price, as: :price
      col :early_bird_price, as: :price

      col :capacity
      col :purchased_event_registrants_count, label: 'Registered'

      col :purchased_event_registrants, label: 'Registrants' do |ticket|
        ticket.purchased_event_registrants.sort_by(&:last_name).map do |registrant|
          content_tag(:div, registrant.last_first_name, class: 'col-resource_item')
        end.join.html_safe
      end

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
      Effective::Event.find(attributes[:event_id])
    end
  end
end
