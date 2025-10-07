module Admin
  class EffectiveEventTicketsDatatable < Effective::Datatable
    datatable do
      order :title

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false
      col :archived

      col :event
      col :title
      col :category, label: 'Purchasable by', visible: false
      col :waitlist, visible: false
      col :guest_of_member, visible: false

      col :early_bird_price, as: :price, visible: false
      col :non_member_price, as: :price, visible: false
      col :member_price, as: :price, visible: false
      col :guest_of_member_price, as: :price, visible: false

      col :prices, label: 'Price' do |ticket|
        prices = []

        if event&.early_bird_end_at.present?
          prices << "#{price_to_currency(ticket.early_bird_price || 0)} early"
        end

        if [ticket.member_price, ticket.non_member_price, ticket.guest_of_member_price].compact.uniq.length == 1
          prices << "#{price_to_currency(ticket.member_price)}"
        else
          if ticket.anyone?
            prices << "#{price_to_currency(ticket.non_member_price)} non-member"
            prices << "#{price_to_currency(ticket.member_price)} member"
          elsif ticket.members?
            prices << "#{price_to_currency(ticket.member_price)} member"
          else
            raise("Invalid ticket category #{ticket.category}")
          end

          if ticket.guest_of_member?
            prices << "#{price_to_currency(ticket.guest_of_member_price)} guest"
          end
        end

        prices.join('<br />')
      end

      col :capacity_available, visible: false
      col :capacity, label: 'Capacity total', visible: false

      col :registrations, label: 'Registrations' do |ticket|
        if ticket.capacity.present?
          "
            #{ticket.capacity} capacity<br />
            #{ticket.registered_non_waitlisted_count} registered<br />
            #{ticket.registered_available_count} available<br />
            #{ticket.registered_waitlisted_count} waitlisted
          "
        else
          "#{ticket.registered_count} registered"
        end
      end

      col :registered_event_registrants_count, label: 'Registered', visible: false, as: :integer do |event|
        event.event_registrants.registered.count
      end

      col :deferred_event_registrants_count, label: 'Deferred', visible: false, as: :integer do |event|
        event.event_registrants.deferred.count
      end

      col :purchased_event_registrants_count, label: 'Purchased', visible: false, as: :integer do |event|
        event.event_registrants.purchased.count
      end

      col :qb_item_name, label: qb_item_name_label, search: Effective::ItemName.sorted.map(&:to_s), visible: false

      col :question1, visible: false
      col :question2, visible: false
      col :question3, visible: false

      col :question1_required, visible: false
      col :question2_required, visible: false
      col :question3_required, visible: false

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
