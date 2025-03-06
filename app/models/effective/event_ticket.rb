# frozen_string_literal: true

module Effective
  class EventTicket < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_tickets_table_name || :event_tickets).to_s

    acts_as_archived

    belongs_to :event

    has_many :event_registrants, -> { order(:id) }, inverse_of: :event_ticket
    accepts_nested_attributes_for :event_registrants

    has_many :purchased_event_registrants, -> { EventRegistrant.purchased.unarchived }, class_name: 'Effective::EventRegistrant'
    has_many :registered_event_registrants, -> { EventRegistrant.registered.unarchived.order(:registered_at).order(:id) }, class_name: 'Effective::EventRegistrant'

    log_changes(to: :event) if respond_to?(:log_changes)

    has_rich_text :body

    CATEGORIES = ['Regular', 'Member Only', 'Member or Non-Member']

    effective_resource do
      title                       :string

      capacity                    :integer
      display_capacity            :boolean
      waitlist                    :boolean 

      category                    :string

      # Questions
      question1                   :text
      question2                   :text
      question3                   :text

      # Pricing
      early_bird_price            :integer
      member_price                :integer
      regular_price               :integer

      qb_item_name                :string
      tax_exempt                  :boolean

      position                    :integer
      archived                    :boolean

      timestamps
    end

    scope :sorted, -> { order(:title) }
    scope :deep, -> { with_rich_text_body.includes(:event, :purchased_event_registrants) }

    before_validation(if: -> { event.present? }) do
      self.category ||= CATEGORIES.first
      self.position ||= (event.event_tickets.map(&:position).compact.max || -1) + 1
    end

    validates :title, presence: true, uniqueness: { scope: [:event_id] }
    validates :category, presence: true

    validates :regular_price, presence: true, if: -> { member_or_non_member? || regular? }
    validates :regular_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :member_price, presence: true, if: -> { member_or_non_member? || member_only? }
    validates :member_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :early_bird_price, presence: true, if: -> { event&.early_bird_end_at.present? }
    validates :early_bird_price, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

    validates :capacity, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
    validates :capacity, presence: { message: 'must be present when using the waitlist'}, if: -> { waitlist? }

    validates :qb_item_name, presence: true, if: -> { EffectiveOrders.require_item_names? }

    def to_s
      title.presence || 'New Event Ticket'
    end

    # These capacity methods are used by the front end EventRegistrations screens
    def capacity_selectable(except: nil)
      return nil if capacity.blank?
      return nil if waitlist?

      capacity_available(except: except)
    end

    def capacity_available(except: nil)
      return nil if capacity.blank?
      [(capacity - capacity_taken(except: except)), 0].max
    end

    def capacity_taken(except: nil)
      registered_or_selected_event_registrants(except: except).reject { |er| er.waitlisted? && !er.promoted? }.length
    end

    def registered_or_selected_event_registrants(except: nil)
      raise('expected except to be an EventRegistration') if except && !except.class.try(:effective_events_event_registration?)

      event_registrants.select do |er| 
        (er.registered? || er.selected_not_expired?) && (except.blank? || er.event_registration_id != except.id) && !er.archived?
      end
    end

    # These registered methods are for the admin registrations screens

    # Total registered count, including waitlisted and non waitlisted
    def registered_count
      registered_event_registrants.length
    end

    # Registered and not waitlisted count
    def registered_non_waitlisted_count
      registered_event_registrants.non_waitlisted.length
    end

    # Registered and waitlisted count
    def registered_waitlisted_count
      registered_event_registrants.waitlisted.length
    end

    # Registered and available count
    def registered_available_count
      return nil if capacity.blank?
      [capacity - registered_non_waitlisted_count, 0].max
    end

    def purchased_event_registrants_count
      purchased_event_registrants.length
    end

    def questions
      [question1.presence, question2.presence, question3.presence].compact
    end

    def regular?
      category == 'Regular'
    end

    def member_only?
      category == 'Member Only'
    end

    def member_or_non_member?
      category == 'Member or Non-Member'
    end
  end
end
