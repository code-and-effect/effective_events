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
      cancelled_at          :datetime     # When the registrant was cancelled by an admin. This also archives it.

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

    before_validation(if: -> { event_ticket_id_changed? && event_ticket_id_was.present? && event_ticket_id.present? }) do
      assign_attributes(waitlisted: false, promoted: false) unless event_ticket.waitlist?
    end

    validate(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      errors.add(:waitlisted, 'is not permitted for a non-waitlist event ticket') if waitlisted? && !event_ticket.waitlist?
    end

    validate(if: -> { event_ticket&.members? }, unless: -> { purchased? }) do
      errors.add(:base, "must be a member") unless owner.try(:membership_present?)
    end

    validate(if: -> { event_ticket&.members? && registrant_validations_enabled? }, unless: -> { purchased? }) do
      errors.add(:user_id, "registrant must be a member") unless event_ticket.guest_of_member? || member?
    end

    validates :price, numericality: { greater_than_or_equal_to: 0 }
    validates :email, email: true

    # First name, last name and email are always required fields on details
    validates :first_name, presence: true, if: -> { registrant_validations_enabled? }
    validates :last_name, presence: true, if: -> { registrant_validations_enabled? }
    validates :email, presence: true, if: -> { registrant_validations_enabled? }

    # User, company and organization conditionally required
    validates :user, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.create_users }
    validates :company, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.company_or_organization_required }
    validates :organization, presence: true, if: -> { registrant_validations_enabled? && EffectiveEvents.company_or_organization_required && EffectiveEvents.organization_enabled? }

    # Responses may or may not be required depending on the event ticket
    validates :response1, presence: true, if: -> { registrant_validations_enabled? && event_ticket&.question1_required? }
    validates :response2, presence: true, if: -> { registrant_validations_enabled? && event_ticket&.question2_required? }
    validates :response3, presence: true, if: -> { registrant_validations_enabled? && event_ticket&.question3_required? }

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
        'Pending Name'
      else
        'Pending Name'
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
        'Pending Name'
      else
        'Pending Name'
      end
    end

    def details
      [
        (content_tag(:span, 'Member', class: 'badge badge-warning') if member?),
        (content_tag(:span, 'Guest of Member', class: 'badge badge-warning') if guest_of_member?),
        (content_tag(:span, 'Waitlist', class: 'badge badge-warning') if waitlisted_not_promoted?),
        (content_tag(:span, 'Archived', class: 'badge badge-warning') if archived? && !cancelled?),
        (content_tag(:span, 'Cancelled', class: 'badge badge-warning') if cancelled?),
      ].compact.join(' ').html_safe
    end

    def responses
      [response1.presence, response2.presence, response3.presence].compact.join('<br>').html_safe
    end

    def purchasable_name
      ["#{event_ticket} - #{name}", details.presence].compact.join('<br>').html_safe
    end

    def last_first_name
      (first_name.present? && last_name.present?) ? "#{last_name}, #{first_name}" : "Pending Name"
    end

    # Anyone or Members tickets
    def early_bird?
      return false if event.blank?
      return false if event_ticket.blank?
      return false if event_ticket.early_bird_price.blank?

      event.early_bird?
    end

    # Anyone or Members tickets
    def member?
      return false if event.blank?
      return false if event_ticket.blank?
      return false if (user.try(:membership_disabled?) || organization.try(:membership_disabled?))

      user.try(:membership_present?) || organization.try(:membership_present?)
    end

    # Anyone or Members tickets
    def guest_of_member?
      return false if event.blank?
      return false if event_ticket.blank?
      return false unless event_ticket.guest_of_member?
      return false if !member? && owner.try(:membership_disabled?)

      !member? && owner.try(:membership_present?)
    end

    # Anyone tickets only
    def non_member?
      return false if event.blank?
      return false if event_ticket.blank?
      return false unless event_ticket.anyone?

      !member? && !guest_of_member?
    end

    # We create registrants on the tickets step. But don't enforce validations until the details step.
    def registrant_validations_enabled?
      return false if blank_registrant? # They want to come back later

      return true if event_registration.blank? # If we're creating in an Admin area
      return false if event_ticket.blank? # Invalid anyway

      event_registration.current_step == :details
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
      return false unless selected_at.present?

      (selected_at + EffectiveEvents.EventRegistration.selection_window) > Time.zone.now
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

      if purchased? && event_registration.present?
        promote_purchased_event_registration!
      elsif purchased? && event_registration.blank?
        promote_purchased_order!
      else
        promote_not_purchased!
      end
    end

    def promote_purchased_event_registration!
      # Remove myself from any existing orders. 
      # I must be $0 so we don't need to update any prices.
      orders.each do |order|
        order.order_items.find { |oi| oi.purchasable == self }.destroy!
      end

      # I'm now promoted and unpurchased
      update!(promoted: true, purchased_order: nil)

      # Check if the ticket owner has an unpurchased event registration for the event or create a new one
      event_registration = EffectiveEvents.EventRegistration.submitted.where(event: event, owner: owner).where.not(id: event_registration_id).first
      event_registration ||= EffectiveEvents.EventRegistration.new(event: event, owner: owner)

      # Put the event registration on the checkout step
      event_registration.all_steps_before(:checkout).each do |step|
        event_registration.wizard_steps[step] ||= Time.zone.now
      end

      event_registration.save!

      # Move this registrant into the new event registration
      update!(event_registration: event_registration)

      # Build the order for the event registration
      # It can be checked out by admin immediately, or the user can go through it themselves
      event_registration.reload
      event_registration.find_or_build_submit_order
      event_registration.save!

      order = event_registration.submit_order

      if order.pending?
        order.defer!(provider: (order.payment_provider.presence || 'cheque'), email: false)
      end

      true
    end

    def promote_purchased_order!
      # Remove myself from any existing orders. 
      # I must be $0 so we don't need to update any prices.
      orders.each do |order|
        order.order_items.find { |oi| oi.purchasable == self }.destroy!
      end

      # I'm now promoted and unpurchased
      update!(promoted: true, purchased_order: nil)

      # Check if the ticket owner has an unpurchased order for the event or create a new one
      order = owner.orders.reject { |order| order.purchased? }.find do |order| 
        order.purchasables.any? { |purchasable| purchasable.class.name == "Effective::EventRegistrant" && purchasable.try(:event) == event }
      end
      order ||= Effective::Order.new(user: owner)

      # Move this registrant into the new order
      order.add(self)

      order.save!

      if order.pending?
        order.defer!(provider: (order.payment_provider.presence || 'cheque'), email: false)
      end

      true
    end

    def promote_not_purchased!
      update!(promoted: true)

      orders.reject(&:purchased?).each do |order| 
        order.update_purchasable_attributes!

        if order.pending?
          order.defer!(provider: (order.payment_provider.presence || 'cheque'), email: false)
        end
      end

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
      assign_attributes(cancelled_at: nil)

      super()
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }
      true
    end

    def cancelled?
      cancelled_at.present?
    end

    # If this changes a lot, consider effective_events_event_registration.cancel!
    def cancel!
      assign_attributes(cancelled_at: Time.zone.now)
      archive!

      after_commit { event_registration&.send_event_registrants_cancelled_email! }

      true
    end

    # If this changes a lot, consider effective_events_event_registration.uncancel!
    def uncancel!
      assign_attributes(cancelled_at: nil)
      unarchive!
    end

    def cancel_all!
      raise("expected an event registration") if event_registration.blank?
      event_registration.cancel!
    end

    def uncancel_all!
      raise("expected an event registration") if event_registration.blank?
      event_registration.uncancel!
    end

    def event_ticket_price
      raise('expected an event') if event.blank?
      raise('expected an event ticket') if event_ticket.blank?

      if early_bird?
        event_ticket.early_bird_price
      elsif blank_registrant? && owner.try(:membership_present?) && !owner.try(:membership_disabled?)
        event_ticket.blank_registrant_member_price
      elsif blank_registrant?
        event_ticket.blank_registrant_non_member_price
      elsif member?
        event_ticket.member_price
      elsif guest_of_member?
        event_ticket.guest_of_member_price
      elsif non_member?
        event_ticket.non_member_price
      else
        event_ticket.maximum_price
      end
    end

    def waitlisted_not_promoted?
      (waitlisted? && !promoted?)
    end

    # Manual admin action only
    def send_confirmation_email!
      send_order_emails!
    end

    # Manual admin action only. From datatable.
    def send_payment_request!
      raise('already purchased or deferred') if purchased_or_deferred?

      order = (Array(event_registration_submit_order) + Array(orders)).find { |order| order.in_progress? && !order.purchased_or_deferred? && !order.refund? }
      return false if order.blank?

      order.send_payment_request!
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
