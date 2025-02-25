module Admin
  class EffectiveEventTicketsDatatable < Effective::Datatable
    datatable do
      reorder :position

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false
      col :archived


      col :event
      col :title
      col :category, visible: false
      col :waitlist, visible: false

      col :early_bird_price, as: :price, visible: false
      col :regular_price, as: :price, visible: false
      col :member_price, as: :price, visible: false

      col :prices do |ticket|
        prices = ""

        if event&.early_bird_end_at.present?
          prices += "#{price_to_currency(ticket.early_bird_price || 0)} early<br />"
        end

        if ticket.category == "Member Only"
          prices += "#{price_to_currency(ticket.member_price)} member"
        elsif ticket.category == "Regular"
          prices += "#{price_to_currency(ticket.regular_price)} regular"
        elsif ticket.category == ("Member or Non-Member" || "Regular")
          prices +=
          "
            #{price_to_currency(ticket.regular_price)} regular<br />
            #{price_to_currency(ticket.member_price)} member
          "
        else
          "Invalid ticket category"
        end

        prices
      end

      col :capacity_available, visible: false
      col :capacity, label: 'Capacity total', visible: false

      col :registrations, label: 'Registrations' do |ticket|
        if ticket.capacity.present?
          "
            #{ticket.capacity} capacity<br />
            #{ticket.non_waitlisted_event_registrants_count.count} registered<br />
            #{ticket.capacity_available} available<br />
            #{ticket.waitlisted_event_registrants_count} waitlisted
          "
        else
          "#{ticket.non_waitlisted_event_registrants_count.count} registered"
        end
      end

      col :category, visible: false

      col :registered_event_registrants_count, label: 'Registered', visible: false, as: :integer do |event|
        event.event_registrants.registered.count
      end

      col :purchased_event_registrants_count, label: 'Deferred', visible: false, as: :integer do |event|
        event.event_registrants.deferred.count
      end

      col :purchased_event_registrants_count, label: 'Purchased', visible: false, as: :integer do |event|
        event.event_registrants.purchased.count
      end

      col :question1, visible: false
      col :question2, visible: false
      col :question3, visible: false

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
      Effective::Event.find_by_id(attributes[:event_id])
    end
  end
end
