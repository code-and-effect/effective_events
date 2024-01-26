# frozen_string_literal: true

module Effective
  class EventProduct < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_products_table_name || :event_products).to_s

    acts_as_archived

    belongs_to :event

    has_many :event_addons
    has_many :purchased_event_addons, -> { EventAddon.purchased.unarchived }, class_name: 'Effective::EventAddon'
    has_many :registered_event_addons, -> { EventAddon.registered.unarchived }, class_name: 'Effective::EventAddon'

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
    scope :deep, -> { with_rich_text_body.includes(:purchased_event_addons) }

    before_validation(if: -> { event.present? }) do
      self.position ||= (event.event_products.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: { scope: [:event_id] }
    validates :price, presence: true

    def to_s
      title.presence || 'New Event Product'
    end

    def capacity_available
      return nil if capacity.blank?
      [(capacity - registered_event_addons_count), 0].max
    end

    def registered_event_addons_count
      registered_event_addons.length
    end

    def purchased_event_addons_count
      purchased_event_addons.length
    end

  end
end
