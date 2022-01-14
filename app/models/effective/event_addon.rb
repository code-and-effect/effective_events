# frozen_string_literal: true

# Just like each EventRegistration has EventTickets and EventRegistrants
# An Event Registration has EventProducts and EventAddons

module Effective
  class EventAddon < ActiveRecord::Base
    acts_as_purchasable

    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event, counter_cache: true

    # Basically a category containing all the pricing and unique info about this product purchase
    belongs_to :event_product

    # Every event registrant is charged to a owner
    belongs_to :owner, polymorphic: true

    # This fee when checked out through the event registration
    belongs_to :event_registration, polymorphic: true, optional: true

    effective_resource do
      notes             :text

      # Acts as Purchasable
      price             :integer
      qb_item_name      :string
      tax_exempt        :boolean

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { all }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    before_validation(if: -> { event_product.present? }) do
      self.price ||= event_product.price
    end

    def to_s
      persisted? ? event_product.to_s : 'product'
    end

    def tax_exempt
      event_product.tax_exempt
    end

    def qb_item_name
      event_product.qb_item_name
    end

    # This is the Admin Save and Mark Paid action
    def mark_paid!
      raise('expected a blank event registration') if event_registration.present?

      save!

      order = Effective::Order.new(items: self, user: owner)
      order.purchase!(skip_buyer_validations: true, email: false)

      true
    end

  end
end
