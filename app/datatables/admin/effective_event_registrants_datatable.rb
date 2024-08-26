module Admin
  class EffectiveEventRegistrantsDatatable < Effective::Datatable
    filters do
      scope :unarchived, label: "All"
      scope :registered
      scope :purchased
      scope :deferred
      scope :not_purchased
      scope :archived
    end

    datatable do
      order :registered_at, :asc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false
      col :archived, visible: false

      col :registered_at

      col :event

      col :owner, visible: false
      col :event_registration, visible: false

      if attributes[:event_id]
        col :event_ticket, search: Effective::EventTicket.where(event: event).all
      else
        col :event_ticket, search: :string
      end

      col :waitlisted do |registrant|
        if registrant.promoted?
          'Promoted'
        elsif registrant.waitlisted?
          'Waitlisted'
        else
          '-'
        end
      end

      col :promoted, visible: false

      col :name do |er|
        if er.user.present?
          "#{link_to(er.user, "/admin/users/#{er.user.id}/edit", target: '_blank')}<br><small>#{mail_to(er.user.email)}</small>"
        elsif er.first_name.present? && er.email.present?
          "#{er.first_name} #{er.last_name}<br><small>#{mail_to(er.email)}</small>"
        elsif er.first_name.present?
          "#{er.first_name} #{er.last_name}"
        elsif er.owner.present?
          er.owner.to_s + ' - GUEST'
        else
          'Unknown'
        end
      end
      
      col :user, label: 'Member', visible: false
      col :organization, visible: false

      col :orders, visible: false
      col :price, as: :price

      col :first_name, visible: false
      col :last_name, visible: false
      col :email, visible: false
      col :company, visible: false

      col :response1
      col :response2
      col :response3

      actions_col
    end

    collection do
      scope = Effective::EventRegistrant.deep.registered

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
