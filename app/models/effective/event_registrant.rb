# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_registrants_table_name || :event_registrants).to_s

    PERMITTED_BLANK_REGISTRANT_CHANGES = ["first_name", "last_name", "email", "company", "user_id", "user_type", "blank_registrant", "response1", "response2", "response3"]

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

      blank_registrant      :boolean
      member_registrant     :boolean

      waitlisted            :boolean

      # Question Responses
      question1             :text
      question2             :text
      question3             :text

      position              :integer
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
    scope :deep, -> { includes(:event, :event_ticket) }
    scope :registered, -> { purchased_or_deferred.unarchived }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    # before_validation(if: -> { event_registration.blank? && event_ticket.present? }) do
    #   self.position ||= (event_ticket.event_registrants.map { |er| er.position }.compact.max || 0) + 1
    # end

    before_validation(if: -> { blank_registrant? }) do
      assign_attributes(user: nil, first_name: nil, last_name: nil, email: nil)
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
    with_options(if: -> { event_ticket&.member_only? }, unless: -> { blank_registrant? }) do
      validates :user_id, presence: { message: 'Please select a member' }
    end

    # Regular Ticket
    with_options(if: -> { event_ticket&.regular? }, unless: -> { blank_registrant? }) do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
    end

    with_options(if: -> { event_ticket&.member_or_non_member? && !blank_registrant? }) do
      validates :user_id, presence: { message: 'Please select a member' }, unless: -> { first_name.present? || last_name.present? || email.present? }
      validates :first_name, presence: true, unless: -> { user.present? }
      validates :last_name, presence: true, unless: -> { user.present? }
      validates :email, presence: true, unless: -> { user.present? }
    end

    def to_s
      persisted? ? title : 'registrant'
    end

    def title
      [event_ticket.to_s, last_first_name, ('WAITLIST' if waitlisted?)].compact.join(' - ')
    end

    def name
      first_name.present? ? "#{first_name} #{last_name}" : "GUEST"
    end

    def last_first_name
      first_name.present? ? "#{last_name}, #{first_name}" : "GUEST"
    end

    def member_present?
      user&.is?(:member) || (blank_registrant? && member_registrant?)
    end

    def tax_exempt
      event_ticket&.tax_exempt
    end

    def qb_item_name
      event_ticket&.qb_item_name
    end

    # This is the Admin Save and Mark Paid action
    def mark_paid!
      raise('expected a blank event registration') if event_registration.present?

      save!

      order = Effective::Order.new(items: self, user: owner)
      order.mark_as_purchased!

      true
    end

    def add_to_waitlist!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(waitlisted: true)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end

    def promote_from_waitlist!
      raise('expected a waitlist? event_ticket') unless event_ticket.waitlist?

      update!(waitlisted: false)
      orders.reject(&:purchased?).each { |order| order.update_purchasable_attributes! }

      true
    end
  
    def registered?
      purchased_or_deferred?
    end

    def <=>(other)
      if purchased? && !other.purchased?
        -1
      elsif !purchased? && other.purchased?
        1
      elsif deferred? && !other.deferred?
        -1
      elsif !deferred? && other.deferred?
        1
      elsif purchased? && other.purchased?
        purchased_at <=> other.purchased_at
      elsif deferred? && other.deferred?
        deferred_at <=> other.deferred_at
      else
        (id || 0) <=> (other.id || 0)
      end
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

    private

    def assign_price
      raise('is already purchased') if purchased?
      assign_attributes(price: (waitlisted ? 0 : event_ticket_price))
    end

  end
end
