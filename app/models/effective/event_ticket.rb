# frozen_string_literal: true

module Effective
  class EventTicket < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_tickets_table_name || :event_tickets).to_s

    acts_as_archived

    belongs_to :event

    has_many :event_registrants, -> { order(:id) }, inverse_of: :event_ticket
    accepts_nested_attributes_for :event_registrants

    has_many :purchased_event_registrants, -> { EventRegistrant.purchased.unarchived }, class_name: 'Effective::EventRegistrant'
    has_many :registered_event_registrants, -> { EventRegistrant.registered.unarchived.order(:registered_at).order(:id) }, class_name: 'Effective::EventRegistrant'

    log_changes(to: :event) if respond_to?(:log_changes)

    has_rich_text :body

    CATEGORIES = ['Regular', 'Member Only', 'Member or Non-Member']

    effective_resource do
      title                       :string

      capacity                    :integer
      waitlist                    :boolean 

      category                    :string

      # Questions
      question1                   :text
      question2                   :text
      question3                   :text

      # Pricing
      early_bird_price            :integer
      member_price                :integer
      regular_price               :integer

      qb_item_name                :string
      tax_exempt                  :boolean

      position                    :integer
      archived                    :boolean

      timestamps
    end

    scope :sorted, -> { order(:position) }
    scope :deep, -> { with_rich_text_body.includes(:event, :purchased_event_registrants) }

    before_validation(if: -> { event.present? }) do
      self.category ||= CATEGORIES.first
      self.position ||= (event.event_tickets.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: { scope: [:event_id] }
    validates :category, presence: true

    validates :regular_price, presence: true, if: -> { member_or_non_member? || regular? }
    validates :regular_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :member_price, presence: true, if: -> { member_or_non_member? || member_only? }
    validates :member_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :early_bird_price, presence: true, if: -> { event&.early_bird_end_at.present? }
    validates :early_bird_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :capacity, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
    validates :capacity, numericality: { greater_than_or_equal_to: 1, message: 'must have a non-zero capacity when using waitlist' }, if: -> { waitlist? }

    def to_s
      title.presence || 'New Event Ticket'
    end

    # This is supposed to be an indempotent big update the world thing
    def update_waitlist!
      return false unless waitlist?

      changed_event_registrants = registered_event_registrants.each_with_index.map do |event_registrant, index|
        next if event_registrant.purchased?

        waitlisted_was = event_registrant.waitlisted?
        waitlisted = (waitlist? && index >= capacity)
        next if waitlisted == waitlisted_was

        event_registrant.update!(waitlisted: waitlisted) # Updates price
        event_registrant
      end.compact

      orders = changed_event_registrants.flat_map { |event_registrant| event_registrant.deferred_orders }.compact.uniq
      orders.each { |order| order.update_purchasable_attributes! }

      true
    end

    def capacity_available
      return nil if capacity.blank?
      [(capacity - registered_event_registrants_count), 0].max
    end

    def registered_event_registrants_count
      registered_event_registrants.length
    end

    def purchased_event_registrants_count
      purchased_event_registrants.length
    end

    def questions
      [question1.presence, question2.presence, question3.presence].compact
    end

    def regular?
      category == 'Regular'
    end

    def member_only?
      category == 'Member Only'
    end

    def member_or_non_member?
      category == 'Member or Non-Member'
    end

    # # purchased, defered, id
    # def sorted_event_registrants
    #   event_registrants.sort do |a, b|
    #     if a.purchased? && !b.purchased?
    #       -1
    #     elsif !a.purchased? && b.purchased?
    #       1
    #     elsif a.deferred? && !b.deferred?
    #       -1
    #     elsif !a.deferred? && b.deferred?
    #       1
    #     elsif a.purchased? && b.purchased?
    #       a.purchased_at <=> b.purchased_at
    #     elsif a.deferred? && b.deferred?
    #       a.deferred_at <=> b.deferred_at
    #     else
    #       (a.id || 0) <=> (b.id || 0)
    #     end
    #   end
    # end

  end
end
