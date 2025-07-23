# frozen_string_literal: true

# Just like each EventRegistration has EventTickets and EventRegistrants
# An Event Registration has EventProducts and EventAddons

module Effective
  class EventAddon < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_addons_table_name || :event_addons).to_s

    acts_as_purchasable
    acts_as_archived

    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event, counter_cache: true

    # Basically a category containing all the pricing and unique info about this product purchase
    belongs_to :event_product

    # Every event registrant is charged to a owner
    belongs_to :owner, polymorphic: true

    # This fee when checked out through the event registration
    belongs_to :event_registration, polymorphic: true, optional: true

    effective_resource do
      first_name        :string
      last_name         :string
      email             :string

      notes             :text

      archived          :boolean

      created_by_admin  :boolean

      # Acts as Purchasable
      price             :integer
      tax_exempt        :boolean
      # The qb_item_name is deferred to event_product

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:event, :event_product) }
    scope :registered, -> { unarchived.purchased_or_deferred.or(where(created_by_admin: true)) }
    scope :purchased_or_created_by_admin, -> { purchased.or(unarchived.where(created_by_admin: true)) }
    scope :not_purchased_not_created_by_admin, -> { not_purchased.where(created_by_admin: false) }

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    before_validation(if: -> { event_product.present? }) do
      assign_attributes(price: event_product.price) unless purchased?
    end

    with_options(if: -> { new_record? }) do
      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true, email: true
    end

    def to_s
      persisted? ? title : 'addon'
    end

    def title
      return event_product.to_s unless first_name.present? && last_name.present?
      "#{event_product} - #{last_first_name}"
    end

    def name
      "#{first_name} #{last_name}"
    end

    def last_first_name
      "#{last_name}, #{first_name}"
    end

    def tax_exempt
      event_product&.tax_exempt
    end

    def qb_item_name
      event_product&.qb_item_name
    end

    def registered?
      purchased_or_deferred?
    end

    # This is the Admin Save and Mark Registered historic action
    def mark_registered!
      raise('expected a blank event registration') if event_registration.present?

      save!

      unless registered?
        order = Effective::Order.new(items: self, user: owner)
        order.purchase!(skip_buyer_validations: true, email: false)
      end

      true
    end

  end
end
