# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    include ActionView::Helpers::TagHelper

    self.table_name = (EffectiveEvents.event_registrants_table_name || :event_registrants).to_s

    attr_accessor :organization_name # Not used. Just for the form.

    PERMITTED_BLANK_REGISTRANT_CHANGES = ["first_name", "last_name", "email", "company", "user_id", "user_type", "blank_registrant", "member_or_non_member_choice", "response1", "response2", "response3"]

    acts_as_purchasable
    acts_as_archived

    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event, counter_cache: true

    # Basically a category containing all the pricing and unique info about htis registrant
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
      company               :string   # Organization name

      blank_registrant      :boolean  # Leave details and come backlater

      waitlisted            :boolean
      promoted              :boolean      # An admin marked this registrant as promoted from the waitlist

      selected_at           :datetime     # When the event registration was selected by a user on the tickets! step
      registered_at         :datetime     # When the order is deferred or purchased

      # Question Responses
      question1             :text
      question2             :text
      question3             :text

      archived              :boolean

      # Acts as Purchasable
      price                 :integer
      qb_item_name          :string
      tax_exempt            :boolean

      # Historical. Not used anymore. TO BE DELETED.
      number                :string
      notes                 :text

      timestamps
    end

    scope :sorted, -> { order(:event_ticket_id, :id) }
    scope :deep, -> { includes(:event, :event_ticket, :owner) }
    scope :registered, -> { where.not(registered_at: nil) }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    before_validation(if: -> { blank_registrant? }) do
      assign_attributes(user: nil, organization: nil, first_name: nil, last_name: nil, email: nil, company: nil)
    end

    before_validation(if: -> { user.present? }) do
      assign_attributes(first_name: user.first_name, last_name: user.last_name, email: user.email)
    end

    before_validation(if: -> { organization.present? }) do
      assign_attributes(company: organization.to_s)
    end

    before_validation(if: -> { user.blank? && first_name.present? && last_name.present? && email.present? }) do
      assign_user()
    end

    before_validation(if: -> { user.present? && organization.blank? && company.present? }) do
      assign_organization()
    end

    before_validation(if: -> { user.present? && organization.present? && company.blank? }) do
      assign_representative()
    end

    before_validation(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      assign_price()
    end

    validate(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      errors.add(:waitlisted, 'is not permitted for a non-waitlist event ticket') if waitlisted? && !event_ticket.waitlist?
    end

    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :email, email: true

    # This works for persisted and adding a new one. But not adding two at same time in a registration
    validates :user_id, uniqueness: { scope: [:event_id], allow_blank: true, message: 'is already registered for this event' }

    # Copy any user errors from assign_user() into the registrant
    validate(if: -> { user && user.new_record? && user.errors.present? }) do
      errors.add(:first_name, user.errors[:first_name].join(', ')) if user.errors[:first_name].present?
      errors.add(:last_name, user.errors[:last_name].join(', ')) if user.errors[:last_name].present?
      errors.add(:email, user.errors[:email].join(', ')) if user.errors[:email].present?

      others = user.errors
        .reject { |error| [:first_name, :last_name, :email].include?(error.attribute) }
        .map { |error| error.full_message }

      errors.add(:base, others.join(', ')) if others.present?
    end

    # When should we do these validations?
    def registrant_validations_enabled?
      return false if blank_registrant? # They want to come back later
      return false if event_ticket.blank? # Invalid anyway
      return true if event_registration.blank? # If we're creating in an Admin area

      [:details, :summary].include?(event_registration.current_step) # Full validations on the details step
    end

    # First name, last name and email are always required fields on details
    with_options(if: -> { registrant_validations_enabled? }) do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
    end

    # Regular Ticket
    with_options(if: -> { registrant_validations_enabled? && event_ticket.regular? }) do
      validates :user_id, presence: true, unless: -> { user&.new_record? }
      validates :company, presence: true
    end

    # Member Only Ticket
    # with_options(if: -> { event_ticket&.member_only? && present_registrant? }) do
    #   validates :user_id, presence: { message: 'Please select a member' }
    # end

    # # Regular Ticket
    # with_options(if: -> { event_ticket&.regular? && present_registrant? }) do
    #   validates :first_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:first_name) }
    #   validates :last_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:last_name) }
    #   validates :email, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:email) }
    #   validates :company, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:company) }
    # end

    # # Member or Non-Member Ticket
    # validates :member_or_non_member_choice, presence: true, if: -> { event_ticket&.member_or_non_member? && present_registrant? }

    # with_options(if: -> { event_ticket&.member_or_non_member? && present_registrant? && member_or_non_member_choice == 'Add a regular registration' }) do
    #   validates :first_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:first_name) }
    #   validates :last_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:last_name) }
    #   validates :email, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:email) }
    #   validates :company, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:company) }
    # end

    # with_options(if: -> { event_ticket&.member_or_non_member? && present_registrant? && member_or_non_member_choice == 'Add a member registration' }) do
    #   validates :user_id, presence: { message: 'Please select a member' }
    # end

    after_defer do
      registered! if event_registration.blank? && !registered?
    end

    after_purchase do
      registered! if event_registration.blank? && !registered?
    end

    def to_s
      persisted? ? title : 'registrant'
    end

    def title
      [event_ticket.to_s, name, ('WAITLIST' if waitlisted_not_promoted?)].compact.join(' - ')
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

    def details
      [
        (content_tag(:span, 'Member', class: 'badge badge-warning') if member_ticket?),
        (content_tag(:span, 'Waitlist', class: 'badge badge-warning') if waitlisted_not_promoted?),
        (content_tag(:span, 'Archived', class: 'badge badge-warning') if event_ticket&.archived?)
      ].compact.join(' ').html_safe
    end

    def purchasable_name
      ["#{event_ticket} - #{name}", details.presence].compact.join('<br>').html_safe
    end

    def last_first_name
      first_name.present? ? "#{last_name}, #{first_name}" : "GUEST"
    end

    def member_present?
      user&.is?(:member)
    end

    def member_ticket?
      return false if event_ticket.blank?

      return true if event_ticket.member_only?
      return true if event_ticket.member_or_non_member? && member_present?

      false
    end

    def member_or_non_member_choice
      self[:member_or_non_member_choice] || 'Add a regular registration'
    end

    def member_email
      email.presence || user&.email
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

    def registered?
      registered_at.present?
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

    private

    def assign_user
      raise('is already purchased') if purchased?

      raise('expected no user') unless user.blank?
      raise('expected a first_name') unless first_name.present?
      raise('expected a last_name') unless last_name.present?
      raise('expected a email') unless email.present?
      raise('expected a user_type') unless user_type.present?

      binding.pry

      if(user_klass = user_type.safe_constantize).present?
        user = user_klass.new(first_name: first_name.strip, last_name: last_name.strip, email: email.strip.downcase, password: SecureRandom.alphanumeric(12))
        assign_attributes(user: user)
      end
    end

    def assign_organization
      raise('is already purchased') if purchased?

      raise('expected no organization') unless organization.blank?
      raise('expected a user') unless user.present?
      raise('expected a email') unless company.present?
      raise('expected a company') unless company.present?
      raise('expected a organization_type') unless organization_type.present?

      organization_klass = organization_type.constantize

      binding.pry
    end

    def assign_representative
      raise('is already purchased') if purchased?

      binding.pry
    end

    def assign_price
      raise('is already purchased') if purchased?

      price = waitlisted_not_promoted? ? 0 : event_ticket_price

      assign_attributes(price: price)
    end

  end
end
