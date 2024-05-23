# frozen_string_literal: true

module Effective
  class EventTicket < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_tickets_table_name || :event_tickets).to_s

    acts_as_archived

    belongs_to :event

    has_many :event_registrants
    has_many :purchased_event_registrants, -> { EventRegistrant.purchased.unarchived }, class_name: 'Effective::EventRegistrant'
    has_many :registered_event_registrants, -> { EventRegistrant.registered.unarchived }, class_name: 'Effective::EventRegistrant'

    log_changes(to: :event) if respond_to?(:log_changes)

    has_rich_text :body

    CATEGORIES = ['Member and Non-Member', 'Member Only', 'Non-Member']

    effective_resource do
      title                       :string
      capacity                    :integer

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

    validates :regular_price, presence: true, if: -> { regular? || non_member? }
    validates :regular_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :member_price, presence: true, if: -> { regular? || member_only? }
    validates :member_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :early_bird_price, presence: true, if: -> { event&.early_bird_end_at.present? }
    validates :early_bird_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    def to_s
      title.presence || 'New Event Ticket'
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
      category == 'Member and Non-Member'
    end

    def member_only?
      category == 'Member Only'
    end

    def non_member?
      category == 'Non-Member'
    end
  end
end
