# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base
    acts_as_purchasable

    log_changes(to: :event) if respond_to?(:log_changes)

    belongs_to :event

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

      # Acts as Purchasable
      price             :integer
      qb_item_name      :string
      tax_exempt        :boolean

      timestamps
    end

    scope :sorted, -> { order(:last_name) }
    scope :deep, -> { all }

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true

    def to_s
      title
    end

    def title
      "#{event.to_s} - #{event_ticket.to_s} - #{first_name} #{last_name}"
    end

    def tax_exempt
      event_ticket.tax_exempt
    end

    def qb_item_name
      event_ticket.qb_item_name
    end

  end
end
