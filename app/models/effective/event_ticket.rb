# frozen_string_literal: true

module Effective
  class EventTicket < ActiveRecord::Base

    belongs_to :event
    has_many :event_registrants

    log_changes(to: :event) if respond_to?(:log_changes)

    effective_resource do
      title  :string
      capacity :integer

      regular_price    :integer
      early_bird_price :integer
      tax_exempt       :boolean

      event_registrants_count :integer # Counter cache

      timestamps
    end

    scope :sorted, -> { order(:title) }
    scope :deep, -> { all }

    validates :title, presence: true
    validates :regular_price, presence: true
    validates :early_bird_price, presence: true

    def to_s
      title.presence || 'New Event Ticket'
    end

    def price
      event.try(:early_bird?) ? early_bird_price : regular_price
    end

    def capacity_available?
      return true if capacity.blank?
      capacity <= event_registrants_count
    end
  end
end
