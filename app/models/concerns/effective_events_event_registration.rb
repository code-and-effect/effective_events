# frozen_string_literal: true

# EffectiveEventsEventRegistration
#
# Mark your owner model with effective_events_event_registration to get all the includes

module EffectiveEventsEventRegistration
  extend ActiveSupport::Concern

  module Base
    def effective_events_event_registration
      include ::EffectiveEventsEventRegistration
    end
  end

  module ClassMethods
    def effective_events_event_registration?; true; end
  end

  included do
    # Needs to be first up here. Before the acts_as_purchasable_parent one voids the order
    around_destroy :around_destroy_deferred_event_registration, if: -> { submit_order&.deferred? }

    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,      # Just Started
      :submitted,  # Order has been submitted with a deferred payment processor.
      :completed   # All done. Order purchased.
    )

    acts_as_wizard(
      start: 'Start',
      tickets: 'Tickets',
      addons: 'Add-ons',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted',
      complete: 'Completed'
    )

    acts_as_purchasable_wizard

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    # Application Namespace
    belongs_to :owner, polymorphic: true
    accepts_nested_attributes_for :owner

    # Effective Namespace
    belongs_to :event, class_name: 'Effective::Event'

    has_many :event_registrants, -> { order(:id) }, class_name: 'Effective::EventRegistrant', inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_registrants, reject_if: :all_blank, allow_destroy: true

    has_many :event_addons, -> { order(:id) }, class_name: 'Effective::EventAddon', inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_addons, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, as: :parent, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders

    # Effective Namespace
    # For coupon fees
    if defined?(EffectiveMemberships)
      has_many :fees, -> { order(:id) }, as: :parent, class_name: 'Effective::Fee', dependent: :nullify
      accepts_nested_attributes_for :fees, reject_if: :all_blank, allow_destroy: true
    end

    effective_resource do
      # Acts as Statused
      status                 :string, permitted: false
      status_steps           :text, permitted: false

      # Dates
      submitted_at           :datetime
      completed_at           :datetime

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { 
      includes(:owner)
      .includes(event: [:rich_texts, event_products: :purchased_event_addons, event_tickets: :purchased_event_registrants])
      .includes(event_registrants: [event_ticket: :purchased_event_registrants])
      .includes(event_addons: [event_product: :purchased_event_addons])
    }

    scope :sorted, -> { order(:id) }
    
    scope :in_progress, -> { where(status: [:draft, :submitted]) }
    scope :done, -> { where(status: :completed) }

    scope :delayed, -> { where(event_id: Effective::Event.delayed) }
    scope :not_delayed, -> { where.not(event_id: Effective::Event.delayed) }

    scope :for, -> (user) { where(owner: user) }

    # All Steps validations
    validates :owner, presence: true
    validates :event, presence: true

    # All Steps
    validate(if: -> { event.present? }) do
      self.errors.add(:base, "cannot register for an external registration event") if event.external_registration?
    end

    # Tickets Step
    validate(if: -> { current_step == :tickets }) do
      self.errors.add(:event_registrants, "can't be blank") unless present_event_registrants.present?
    end

    # Validate all tickets are available for registration
    validate(if: -> { current_step == :tickets }) do
      unavailable_event_tickets.each do |event_ticket|
        errors.add(:base, "The requested number of #{event_ticket} tickets are not available")
      end
    end

    # Validate all products are available for registration
    validate(if: -> { current_step == :addons }) do
      unavailable_event_products.each do |event_product|
        errors.add(:base, "The requested number of #{event_product} add-ons are not available")
      end
    end

    # If we're submitted. Try to move to completed.
    before_save(if: -> { submitted? }) { try_completed! }

    def around_destroy_deferred_event_registration
      raise('expecting a deferred submit order') unless submit_order&.deferred?

      waitlisted_event_tickets_was = event_tickets().select(&:waitlist?)
      yield
      waitlisted_event_tickets_was.each { |event_ticket| event_ticket.update_waitlist! }
      true
    end

    def delayed_payment_date_upcoming?
      event&.delayed_payment_date_upcoming?
    end

    def can_visit_step?(step)
      return false if step == :complete && !completed?
      return true if step == :complete && completed?

      # If submitted with a cheque/phone deferred (but not delayed) processor then lock down the steps.
      if submitted? && !delayed_payment_date_upcoming?
        return (step == :submitted) 
      end

      # Add ability to edit registrations up until payment date
      if submitted? && delayed_payment_date_upcoming?
        return can_revisit_completed_steps(step)
      end

      # Default
      can_revisit_completed_steps(step)
    end

    def required_steps
      return self.class.test_required_steps if Rails.env.test? && self.class.test_required_steps.present?
      event&.event_products.unarchived.present? ? wizard_step_keys : (wizard_step_keys - [:addons])
    end

    def find_or_build_submit_fees
      with_outstanding_coupon_fees(submit_fees)
    end

    def delayed_payment_attributes
      { delayed_payment: event&.delayed_payment, delayed_payment_date: event&.delayed_payment_date }
    end

    # All Fees and Orders
    def submit_fees
      if defined?(EffectiveMemberships)
        (event_registrants + event_addons + fees)
      else
        (event_registrants + event_addons)
      end
    end

    # When the submit_order is deferred or purchased, we call submit!
    # When the order is a deferred payment processor, we continue to the :submitted step
    # When the order is a regular processor, the before_save will call complete! and we continue to the :complete step
    # Purchasing the order later on will automatically call 
    def submit_wizard_on_deferred_order?
      true
    end

    def after_submit_deferred!
      update_deferred_event_registration!
    end

    def after_submit_purchased!
      event_registrants.each { |event_registrant| event_registrant.registered! }

      notifications = event.event_notifications.select(&:registrant_purchased?)
      notifications.each { |notification| notification.notify!(event_registrants: event_registrants) }
    end
  end

  # Instance Methods
  def to_s
    'registration'
  end

  def in_progress?
    draft? || submitted?
  end

  def done?
    completed?
  end

  def tickets!
    after_commit do
      update_submit_fees_and_order! if submit_order.present?
      update_deferred_event_registration! if submit_order&.deferred?
    end

    save!
  end

  def addons!
    after_commit do
      update_submit_fees_and_order! if submit_order.present?
    end

    save!
  end

  def try_completed!
    return false unless submitted?
    return false unless submit_order&.purchased?
    complete!
  end

  def complete!
    raise('event registration must be submitted to complete!') unless submitted?
    raise('expected a purchased order') unless submit_order&.purchased?

    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] ||= Time.zone.now
    wizard_steps[:complete] = Time.zone.now

    completed!
    true
  end

  # Find or build
  def event_registrant(event_ticket:, first_name:, last_name:, email:)
    registrant = event_registrants.find { |er| er.event_ticket == event_ticket && er.first_name == first_name && er.last_name == last_name && er.email == email }
    registrant || event_registrants.build(event: event, event_ticket: event_ticket, owner: owner, first_name: first_name, last_name: last_name, email: email)
  end

  # Find or build. But it's not gonna work with more than 1. This is for testing only really.
  def event_addon(event_product:, first_name:, last_name:, email:)
    addon = event_addons.find { |er| er.event_product == event_product && er.first_name == first_name && er.last_name == last_name && er.email == email }
    addon || event_addons.build(event: event, event_product: event_product, owner: owner, first_name: first_name, last_name: last_name, email: email)
  end

  # This builds the default event registrants used by the wizard form
  def build_event_registrants
    if event_registrants.blank?
      raise('expected owner and event to be present') unless owner && event

      event_registrants.build()
    end

    event_registrants
  end

  # This builds the default event addons used by the wizard form
  def build_event_addons
    if event_addons.blank?
      raise('expected owner and event to be present') unless owner && event

      event_addons.build(
        first_name: owner.try(:first_name),
        last_name: owner.try(:last_name),
        email: owner.try(:email)
      )
    end

    event_addons
  end

  def event_tickets
    present_event_registrants.map(&:event_ticket).uniq
  end

  def unavailable_event_tickets
    unavailable = []

    present_event_registrants.map(&:event_ticket).group_by { |t| t }.each do |event_ticket, event_tickets|
      unless event_ticket.waitlist? || event.event_ticket_available?(event_ticket, quantity: event_tickets.length)
        unavailable << event_ticket 
      end
    end

    unavailable
  end

  def unavailable_event_products
    unavailable = []

    present_event_addons.map(&:event_product).group_by { |p| p }.each do |event_product, event_products|
      unavailable << event_product unless event.event_product_available?(event_product, quantity: event_products.length)
    end

    unavailable
  end

  def event_ticket_member_users
    raise("expected owner to be a user") if owner.class.try(:effective_memberships_organization?)
    users = [owner] + (owner.try(:organizations).try(:flat_map, &:users) || [])

    users.select { |user| user.is_any?(:member) }.uniq
  end

  def update_blank_registrants!
    # This method is called by the user on a submitted or completed event registration.
    # Allow them to update blank registrants
    # Don't let them hack the form and change any information.
    if changes.present? || previous_changes.present?
      raise('unable to make changes to event while updating blank registrants')
    end

    if event_registrants.any? { |er| (er.changes.keys - Effective::EventRegistrant::PERMITTED_BLANK_REGISTRANT_CHANGES).present? }
      raise('unable to make changes to event registrants while updating blank registrants')
    end

    if event_registrants.any? { |er| er.blank_registrant_was == false && er.changes.present? }
      raise('unable to make changes to non-blank registrant while updating blank registrants')
    end

    if event_addons.any? { |ea| ea.changes.present? }
      raise('unable to make changes to event addons while updating blank registrants')
    end

    save!

    update_submit_fees_and_order! if submit_order.present? && !submit_order.purchased?

    true
  end

  private

  def update_deferred_event_registration!
    raise('expected a deferred submit order') unless submit_order&.deferred?

    # Mark registered anyone who hasn't been registered yet. They are now!
    event_registrants.reject(&:registered?).each { |event_registrant| event_registrant.registered! }

    # Update the waitlist for any event tickets
    event_tickets.select(&:waitlist?).each { |event_ticket| event_ticket.update_waitlist! }

    true
  end

  def present_event_registrants
    event_registrants.reject(&:marked_for_destruction?).reject(&:archived?)
  end

  def present_event_addons
    event_addons.reject(&:marked_for_destruction?).reject(&:archived?)
  end

end
