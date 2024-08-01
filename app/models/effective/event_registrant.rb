# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_registrants_table_name || :event_registrants).to_s

    PERMITTED_BLANK_REGISTRANT_CHANGES = ["first_name", "last_name", "email", "company", "user_id", "user_type", "blank_registrant", "member_or_non_member_choice", "response1", "response2", "response3"]
    MEMBER_OR_NON_MEMBER_CHOICES = ['Add a regular registration', 'Add a member registration']

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

    # Required for member-only tickets. The user attending.
    belongs_to :user, polymorphic: true, optional: true

    effective_resource do
      first_name            :string
      last_name             :string
      email                 :string
      company               :string

      blank_registrant             :boolean
      member_or_non_member_choice  :string       # Used by Member or Non-Member tickets to indicate a member or non-member

      waitlisted            :boolean
      promoted              :boolean      # An admin marked this registrant as promoted from the waitlist
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

    scope :sorted, -> { order(:last_name) }
    scope :deep, -> { includes(:event, :event_ticket, :owner) }
    scope :registered, -> { where.not(registered_at: nil) }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    before_validation(if: -> { blank_registrant? }) do
      assign_attributes(user: nil, first_name: nil, last_name: nil, email: nil, company: nil)
    end

    before_validation(if: -> { user.present? }) do
      assign_attributes(first_name: user.first_name, last_name: user.last_name, email: user.email)
    end

    before_validation(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      assign_price()
    end

    validate(if: -> { event_ticket.present? }, unless: -> { purchased? }) do
      errors.add(:waitlisted, 'is not permitted for a non-waitlist event ticket') if waitlisted? && !event_ticket.waitlist?
    end

    validates :user_id, uniqueness: { scope: [:event_id], allow_blank: true, message: 'is already registered for this event' }
    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :email, email: true

    # Member Only Ticket
    with_options(if: -> { event_ticket&.member_only? && present_registrant? }) do
      validates :user_id, presence: { message: 'Please select a member' }
    end

    # Regular Ticket
    with_options(if: -> { event_ticket&.regular? && present_registrant? }) do
      validates :first_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:first_name) }
      validates :last_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:last_name) }
      validates :email, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:email) }
      validates :company, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:company) }
    end

    # Member or Non-Member Ticket
    validates :member_or_non_member_choice, presence: true, if: -> { event_ticket&.member_or_non_member? && present_registrant? }

    with_options(if: -> { event_ticket&.member_or_non_member? && present_registrant? && member_or_non_member_choice == 'Add a regular registration' }) do
      validates :first_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:first_name) }
      validates :last_name, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:last_name) }
      validates :email, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:email) }
      validates :company, presence: true, unless: -> { EffectiveEvents.event_registrant_required_fields.exclude?(:company) }
    end

    with_options(if: -> { event_ticket&.member_or_non_member? && present_registrant? && member_or_non_member_choice == 'Add a member registration' }) do
      validates :user_id, presence: { message: 'Please select a member' }
    end

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

    def last_first_name
      first_name.present? ? "#{last_name}, #{first_name}" : "GUEST"
    end

    def member_present?
      user&.is?(:member)
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

    def registered?
      registered_at.present?
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

    def assign_price
      raise('is already purchased') if purchased?

      price = waitlisted_not_promoted? ? 0 : event_ticket_price

      assign_attributes(price: price)
    end

  end
end
