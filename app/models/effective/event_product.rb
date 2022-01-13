# frozen_string_literal: true

module Effective
  class EventProduct < ActiveRecord::Base
    belongs_to :event

    has_many :event_purchases
    has_many :purchased_event_purchases, -> { EventPurchase.purchased }, class_name: 'Effective::EventPurchase'

    log_changes(to: :event) if respond_to?(:log_changes)

    has_rich_text :body

    effective_resource do
      title                 :string
      capacity              :integer

      # Pricing
      price                 :integer

      qb_item_name          :string
      tax_exempt            :boolean

      position              :integer
      archived              :boolean

      timestamps
    end

    scope :sorted, -> { order(:position) }
    scope :deep, -> { with_rich_text_body.includes(:purchased_event_purchases) }

    scope :archived, -> { where(archived: true) }
    scope :unarchived, -> { where(archived: false) }

    before_validation(if: -> { event.present? }) do
      self.position ||= (event.event_products.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: { scope: [:event_id] }
    validates :price, presence: true

    def to_s
      title.presence || 'New Event Product'
    end

    # Available for purchase
    def available?
      return false if archived?
      capacity_available?
    end

    def capacity_available?
      capacity.blank? || (capacity_available > 0)
    end

    def capacity_available
      return nil if capacity.blank?
      [(capacity - purchased_event_purchases_count), 0].max
    end

    def purchased_event_purchases_count
      purchased_event_purchases.length
    end

  end
end
