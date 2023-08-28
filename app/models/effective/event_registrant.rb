# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_registrants_table_name || :event_registrants).to_s

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

    effective_resource do
      first_name    :string
      last_name     :string
      email         :string

      company       :string
      number        :string
      notes         :text

      archived      :boolean

      # Acts as Purchasable
      price             :integer
      qb_item_name      :string
      tax_exempt        :boolean

      timestamps
    end

    scope :sorted, -> { order(:last_name) }
    scope :deep, -> { includes(:event, :event_ticket) }

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, email: true

    before_validation(if: -> { event_registration.present? }) do
      self.event ||= event_registration.event
      self.owner ||= event_registration.owner
    end

    before_validation(if: -> { event_ticket.present? }) do
      self.price ||= event_ticket.price
    end

    def to_s
      persisted? ? title : 'registrant'
    end

    def title
      "#{event_ticket} - #{last_first_name}"
    end

    def name
      "#{first_name} #{last_name}"
    end

    def last_first_name
      "#{last_name}, #{first_name}"
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

  end
end
