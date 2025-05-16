# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    include ActionView::Helpers::TagHelper

    self.table_name = (EffectiveEvents.event_registrants_table_name || :event_registrants).to_s

    PERMITTED_BLANK_REGISTRANT_CHANGES = ["first_name", "last_name", "email", "company", "user_id", "user_type", "organization_id", "organization_type", "blank_registrant", "response1", "response2", "response3"]

    attr_accessor :building_user_and_organization

    acts_as_purchasable
    acts_as_archived

    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event, counter_cache: true

    # Basically a category containing all the pricing and unique info about this registrant
    belongs_to :event_ticket

    # Every event registrant is charged to a owner
    belongs_to :owner, polymorphic: true

    # This fee when checked out through the event registration
    belongs_to :event_registration, polymorphic: true, optional: true

    # The user for this registrant
    belongs_to :user, polymorphic: true, optional: true
    accepts_nested_attributes_for :user

    # The organization for this registrant
    belongs_to :organization, polymorphic: true, optional: true
    accepts_nested_attributes_for :organization

    effective_resource do
      first_name            :string
      last_name             :string
      email                 :string
      company               :string       # Organization name

      blank_registrant      :boolean      # Leave details and come back later

      waitlisted            :boolean
      promoted              :boolean      # An admin marked this registrant as promoted from the waitlist

      selected_at           :datetime     # When the event registration was selected by a user on the tickets! step
      registered_at         :datetime     # When the order is deferred or purchased

      # Question Responses
      response1             :text
      response2             :text
      response3             :text

      archived              :boolean

      created_by_admin      :boolean

      # Acts as Purchasable
      price                 :integer
      tax_exempt            :boolean
      # The qb_item_name is deferred to ticket

      # Historical. Not used anymore. TO BE DELETED.
      number                :string
      notes                 :text

      timestamps
    end

    scope :sorted, -> { order(:event_ticket_id, :id) }
    scope :deep, -> { includes(:event, :event_ticket, :owner, :user, event_registration: :orders) }
    scope :registered, -> { unarchived.where.not(registered_at: nil) }
    scope :not_registered, -> { archived.or(where(registered_at: nil)) }
    scope :purchased_or_created_by_admin, -> { purchased.or(unarchived.where(created_by_admin: true)) }
    scope :not_purchased_not_created_by_admin, -> { not_purchased.where(created_by_admin: false) }

    scope :waitlisted, -> { where(waitlisted: true, promoted: false) }
    scope :non_waitlisted, -> { where(waitlisted: false).or(where(waitlisted: true, promoted: true)) }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    with_options(unless: -> { purchased? && !blank_registrant_was }) do
      before_validation(if: -> { blank_registrant? }) do
        assign_attributes(user: nil, organization: nil, first_name: nil, last_name: nil, email: nil, company: nil)
      end

      before_validation(if: -> { user.blank? }) do
        assign_attributes(building_user_and_organization: true) # For member-only ticket validations
      end

      before_validation(if: -> { user.blank? && first_name.present? && last_name.present? && email.present? }) do
        build_user() if EffectiveEvents.create_users
        build_organization_and_representative() if EffectiveEvents.organization_enabled?
      end

      before_validation(if: -> { user.present? }) do
        assign_attributes(first_name: user.first_name, last_name: user.last_name, email: (user.try(:public_email).presence || user.email))
      end

      before_validation(if: -> { organization.blank? && user.present? && user.class.try(:effective_memberships_organization_user?) }) do
        assign_attributes(company: user.organizations.first.to_s.presence) if company.blank?
      end

      before_validation(if: -> { organization.present? }) do
        assign_attributes(company: organization.to_s)
      end
    end

    before_validation(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      assign_price()
    end

    validate(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      errors.add(:waitlisted, 'is not permitted for a non-waitlist event ticket') if waitlisted? && !event_ticket.waitlist?
    end

    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :email, email: true

    # First name, last name and email are always required fields on details
    validates :first_name, presence: true, if: -> { registrant_validations_enabled? }
    validates :last_name, presence: true, if: -> { registrant_validations_enabled? }
    validates :email, presence: true, if: -> { registrant_validations_enabled? }

    # User, company and organization conditionall required
    validates :user, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.create_users }
    validates :company, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.company_or_organization_required }
    validates :organization, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.company_or_organization_required && EffectiveEvents.organization_enabled? }

    # Member ticket: company name is locked in. you can only add to your own company
    validate(if: -> { registrant_validations_enabled? && event_ticket&.member_only? }) do
      if building_user_and_organization && owner.present? && Array(owner.try(:organizations)).exclude?(organization)
        errors.add(:organization_id, "must be your own for member-only tickets") 
      end

      errors.add(:user_id, 'must be a member to register for member-only tickets') unless member_present?
    end

    # Copy any user errors from build_user_and_organization() into the registrant
    after_validation(if: -> { user && user.new_record? && user.errors.present? }) do
      errors.add(:first_name, user.errors[:first_name].join(', ')) if user.errors[:first_name].present?
      errors.add(:last_name, user.errors[:last_name].join(', ')) if user.errors[:last_name].present?
      errors.add(:email, user.errors[:email].join(', ')) if user.errors[:email].present?

      others = user.errors.reject { |error| [:first_name, :last_name, :email].include?(error.attribute) }
      errors.add(:base, others.map(&:full_message).join(', ')) if others.present?
    end

    # Copy any organization errors from build_user_and_organization() into the registrant
    after_validation(if: -> { organization && organization.new_record? && organization.errors.present? }) do
      errors.add(:company, organization.errors.full_messages.join(', '))
    end

    after_defer do
      registered! if event_registration.blank? && !registered?
    end

    after_purchase do
      registered! if event_registration.blank? && !registered?
    end

    # Build an event registration for this registrant with a $0 purchased order
    after_commit(if: -> { event_registration.blank? && created_by_admin? }) do
      event_registration = EffectiveEvents.EventRegistration.new(event: event, owner: owner)
      event_registration.event_registrants << self
      event_registration.build_submit_fees_and_order()
      event_registration.save!

      order = event_registration.submit_order
      order.order_items.each { |oi| oi.assign_attributes(price: 0) }
      order.order_items.each { |oi| oi.purchasable.assign_attributes(price: 0) }
      order.mark_as_purchased!

      order.update_columns(subtotal: 0, total: 0, tax: 0, amount_owing: 0)
    end

    def to_s
      persisted? ? title : 'registrant'
    end

    def title
      ["#{event_ticket} - #{name}", details.presence].compact.join(' ').html_safe
    end

    def name
      if first_name.present?
        "#{first_name} #{last_name}"
      elsif owner.present?
        owner.to_s + ' - GUEST'
      else
        'GUEST'
      end
    end

    # Used in email and tickets datatable
    def full_name
      if first_name.present?
        [
          name,
          ("<small>#{organization || company}</small>" if organization || company.present?),
          ("<small>#{email}</small>" if email.present?)
        ].compact.join('<br>').html_safe
      elsif owner.present?
        owner.to_s + ' - GUEST'
      else
        'GUEST'
      end
    end

    def details
      [
        (content_tag(:span, 'Member', class: 'badge badge-warning') if member_ticket?),
        (content_tag(:span, 'Waitlist', class: 'badge badge-warning') if waitlisted_not_promoted?),
        (content_tag(:span, 'Archived', class: 'badge badge-warning') if archived?)
      ].compact.join(' ').html_safe
    end

    def responses
      [response1.presence, response2.presence, response3.presence].compact.join('<br>').html_safe
    end

    def purchasable_name
      ["#{event_ticket} - #{name}", details.presence].compact.join('<br>').html_safe
    end

    def last_first_name
      (first_name.present? && last_name.present?) ? "#{last_name}, #{first_name}" : "GUEST"
    end

    # We create registrants on the tickets step. But don't enforce validations until the details step.
    def registrant_validations_enabled?
      return false if blank_registrant? # They want to come back later

      return true if event_registration.blank? # If we're creating in an Admin area
      return false if event_ticket.blank? # Invalid anyway

      event_registration.current_step == :details
    end

    def member_present?
      user.try(:membership_present?) || organization.try(:membership_present?)
    end

    def member_ticket?
      return false if event_ticket.blank?
      return true if event_ticket.member_only?
      return true if event_ticket.member_or_non_member? && member_present?

      false
    end

    def present_registrant?
      !blank_registrant?
    end

    def tax_exempt
      event_ticket&.tax_exempt
    end

    def qb_item_name
      event_ticket&.qb_item_name
    end

    def selected?
      selected_at.present?
    end

    def registered?
      registered_at.present?
    end

    def selected_not_expired?
      return false unless EffectiveEvents.EventRegistration.selection_window.present?
      selected_at.present? && (selected_at + EffectiveEvents.EventRegistration.selection_window > Time.zone.now)
    end

    # Called by an event_registration after_defer and after_purchase
    def registered!
      self.registered_at ||= Time.zone.now
      save!
    end

    # This is the Admin Save and Mark Registered action
    def mark_registered!
      registered!
    end

    # Admin update event registrant action
    def save_and_update_orders!
      if event_ticket_id_changed?
        assign_attributes(response1: nil, response2: nil, response3: nil)
      end

      save!

      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def waitlist!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(waitlisted: true)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def unwaitlist!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(waitlisted: false)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def promote!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(promoted: true)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def unpromote!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(promoted: false)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def archive!
      super()
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }
      true
    end

    def unarchive!
      super()
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }
      true
    end

    def event_ticket_price
      raise('expected an event') if event.blank?
      raise('expected an event ticket') if event_ticket.blank?

      if event.early_bird?
        event_ticket.early_bird_price # Early Bird Pricing
      elsif event_ticket.regular?
        event_ticket.regular_price
      elsif event_ticket.member_only?
        event_ticket.member_price
      elsif event_ticket.member_or_non_member?
        (member_present? ? event_ticket.member_price : event_ticket.regular_price)
      else
        raise("Unexpected event ticket price calculation")
      end
    end

    def waitlisted_not_promoted?
      (waitlisted? && !promoted?)
    end

    # Manual admin action only
    def send_confirmation_email!
      send_order_emails!
    end

    def send_order_emails!
      event_registration&.submit_order&.send_order_emails!
    end

    def event_registration_submit_order
      event_registration&.submit_order
    end

    private

    def build_user
      raise('is already purchased') if purchased?
      raise('expected no user') unless user.blank?
      raise('expected a first_name') unless first_name.present?
      raise('expected a last_name') unless last_name.present?
      raise('expected a email') unless email.present?

      return if user_type.blank?

      # Add User
      user_klass = user_type.constantize

      # First we lookup the user by email. If they actually exist we ignore all other fields
      existing_user = user_klass.find_by_any_email(email.strip.downcase)

      if existing_user.present?
        assign_attributes(user: existing_user)

        if EffectiveEvents.organization_enabled? && user_klass.try(:effective_memberships_organization_user?)
          assign_attributes(organization: existing_user.organizations.first) if existing_user.organizations.present?
        end
      else
        # Otherwise create a new user
        new_user = user_klass.create(
          first_name: first_name.strip, 
          last_name: last_name.strip, 
          email: email.strip.downcase, 
          password: SecureRandom.base64(12) + '!@#123abcABC-'
        )

        assign_attributes(user: new_user)
      end

      user.valid?
    end

    # The organization might already be set here
    def build_organization_and_representative
      raise('is already purchased') if purchased?

      return if organization_type.blank?

      # We previously created an invalid user
      return if user.present? && user.errors.present?

      # Add Organization and representative
      organization_klass = organization_type.constantize

      # Find or create the organization
      if organization.present?
        user.build_representative(organization: organization) if user.present?
      elsif company.present?
        new_organization = organization_klass.where(title: company.strip).first
        new_organization ||= organization_klass.create(title: company.strip, email: email.strip.downcase)
        assign_attributes(organization: new_organization)

        user.build_representative(organization: new_organization) if user.present?
      end

      true
    end

    def assign_price
      raise('is already purchased') if purchased?

      price = (waitlisted_not_promoted? || archived?) ? 0 : event_ticket_price

      assign_attributes(price: price)
    end

  end
end
