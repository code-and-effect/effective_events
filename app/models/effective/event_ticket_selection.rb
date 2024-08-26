# frozen_string_literal: true

# Form object to select a # of tickets on the EventRegistration form

module Effective
  class EventTicketSelection < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_ticket_selections_table_name || :event_ticket_selections).to_s

    belongs_to :event_registration, polymorphic: true
    belongs_to :event_ticket

    effective_resource do
      quantity        :integer

      timestamps
    end

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:event_registration, :event_ticket) }

    validates :quantity, numericality: { greater_than_or_equal_to: 0 }

    def to_s
      persisted? ? "#{quantity}x #{event_ticket}": model_name.human
    end

  end
end
