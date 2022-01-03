# frozen_string_literal: true

module Effective
  class EventTicket < ActiveRecord::Base
    belongs_to :event

    has_many :event_registrants
    has_many :purchased_event_registrants, -> { EventRegistrant.purchased }

    log_changes(to: :event) if respond_to?(:log_changes)

    has_rich_text :body

    effective_resource do
      title                 :string
      capacity              :integer

      # Pricing
      regular_price         :integer
      early_bird_price      :integer

      qb_item_name          :string
      tax_exempt            :boolean

      position                  :integer

      timestamps
    end

    scope :sorted, -> { order(:position) }
    scope :deep, -> { with_rich_text_body }

    before_validation(if: -> { event.present? }) do
      self.position ||= (event.event_tickets.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true
    validates :regular_price, presence: true
    validates :early_bird_price, presence: true, if: -> { event&.early_bird_end_at.present? }

    def to_s
      title.presence || 'New Event Ticket'
    end

    def price
      event&.early_bird? ? early_bird_price : regular_price
    end

    def capacity_available?
      return true if capacity.blank?
      capacity <= purchased_event_registrants.count
    end
  end
end
