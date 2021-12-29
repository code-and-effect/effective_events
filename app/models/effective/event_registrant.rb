# frozen_string_literal: true

module Effective
  class EventRegistrant < ActiveRecord::Base

    # belongs_to :user # the person who made the purchase
    belongs_to :event
    belongs_to :event_ticket, counter_cache: true

    log_changes(to: :event) if respond_to?(:log_changes)

    effective_resource do
      first_name   :string
      last_name    :string
      email        :string
      company      :string
      number       :string
      restrictions :text

      timestamps
    end

    # TODO add purchase hook
    # after_purchase do |order, order_item|
    #   event_registration.finish! unless event_registration.finished?
    # end

    scope :sorted, -> { order(:last_name) }
    scope :deep, -> { all }

    validates :event, presence: true
    validates :event_ticket, presence: true
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true

    def to_s
      title
    end

    def title
      "#{event.to_s} - #{event_ticket.to_s} - #{first_name} #{last_name}"
    end

  end
end
