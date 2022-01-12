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

      timestamps
    end

    scope :sorted, -> { order(:position) }
    scope :deep, -> { with_rich_text_body.includes(:purchased_event_purchases) }

    before_validation(if: -> { event.present? }) do
      self.position ||= (event.event_products.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: { scope: [:event_id] }
    validates :price, presence: true

    def to_s
      title.presence || 'New Event Product'
    end

    def capacity_available?
      return true if capacity.blank?
      capacity <= purchased_event_purchases.count
    end

    def purchased_event_purchases_count
      purchased_event_purchases.count
    end

  end
end
