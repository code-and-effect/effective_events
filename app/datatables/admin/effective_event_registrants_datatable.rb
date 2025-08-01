module Admin
  class EffectiveEventRegistrantsDatatable < Effective::Datatable
    filters do
      scope :registered
      scope :not_registered
      scope :purchased_or_created_by_admin, label: 'Purchased'
      scope :deferred
      scope :not_purchased_not_created_by_admin, label: 'Not Purchased'
      scope :archived
      scope :all
    end

    datatable do
      order :registered_at, :desc

      col :updated_at, visible: false
      col :created_at, visible: false
      col :id, visible: false

      col :registered_at

      col :event

      col :owner
      col :event_registration, visible: false

      if defined?(EffectiveMemberships) && EffectiveMemberships.Organization.respond_to?(:sponsors)
        col :sponsorship, search: EffectiveMemberships.Organization::SPONSORSHIPS, visible: false do |er|
          er.user.try(:sponsorship)
        end
      end

      if attributes[:event_id]
        col :event_ticket, search: Effective::EventTicket.where(event: event).all
      else
        col :event_ticket
      end

      col :waitlisted do |registrant|
        if registrant.promoted?
          'Promoted'
        elsif registrant.waitlisted?
          'Waitlisted'
        else
          '-'
        end
      end.search do |collection, term|
        EffectiveResources.truthy?(term) ? collection.waitlisted : collection.non_waitlisted
      end

      col :promoted, visible: false
      col :archived, visible: false

      col :name do |er|
        if er.user.present?
          "#{link_to(er.user, "/admin/users/#{er.user.id}/edit", target: '_blank')}<br><small>#{mail_to(er.user.email)}</small>"
        elsif er.first_name.present? && er.email.present?
          "#{er.first_name} #{er.last_name}<br><small>#{mail_to(er.email)}</small>"
        elsif er.first_name.present?
          "#{er.first_name} #{er.last_name}"
        elsif er.owner.present?
          'Pending Name'
        else
          'Pending Name'
        end
      end
      
      col :user, visible: false
      col :organization, visible: EffectiveEvents.organization_enabled?
      col :company, visible: !EffectiveEvents.organization_enabled?

      col :orders, visible: false

      col(:price, as: :price) do |registrant|
        [
          (badge('ADMIN') if registrant.created_by_admin?),
          price_to_currency(registrant.price)
        ].compact.join(' ').html_safe
      end

      col :created_by_admin, visible: false

      col :first_name, visible: false
      col :last_name, visible: false
      col :email, visible: false

      col :response1
      col :response2
      col :response3

      actions_col do |registrant|
        if EffectiveResources.authorized?(self, :impersonate, registrant.owner)
          dropdown_link_to("Impersonate", "/admin/users/#{registrant.owner_id}/impersonate", data: { confirm: "Really impersonate #{registrant.owner}?", method: :post, remote: true })
        end
      end
    end

    collection do
      scope = Effective::EventRegistrant.deep.all

      if attributes[:event_id].present?
        scope = scope.where(event: event)
      end

      if (user_id = attributes[:for_id]).present? && (user_type = attributes[:for_type]).present?
        scope = scope.where(user_id: user_id, user_type: user_type).or(scope.where(owner_id: user_id, owner_type: user_type))
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
