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

    def selection_window
      30.minutes
    end
  end

  included do
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
      details: 'Ticket Details',
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

    has_many :event_ticket_selections, -> { order(:id) }, class_name: 'Effective::EventTicketSelection', inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_ticket_selections, reject_if: :all_blank, allow_destroy: true

    has_many :event_registrants, -> { order(:event_ticket_id, :id) }, class_name: 'Effective::EventRegistrant', inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_registrants, reject_if: :all_blank, allow_destroy: true

    has_many :event_addons, -> { order(:event_product_id, :id) }, class_name: 'Effective::EventAddon', inverse_of: :event_registration, dependent: :destroy
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
      .includes(event_ticket_selections: [:event_ticket])
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
      errors.add(:base, "cannot register for an external registration event") if event.external_registration?
    end

    # Tickets Step
    validate(if: -> { current_step == :tickets }) do
      if event_ticket_selections.all? { |selection| selection.quantity.to_i == 0 }
        errors.add(:event_ticket_selections, "Please select one or more tickets")
        event_ticket_selections.each { |ets| ets.errors.add(:quantity, "can't be blank") }
      end
    end

    # Validate all tickets are available for registration
    validate(if: -> { current_step == :tickets }) do
      unavailable_event_tickets.each do |event_ticket|
        errors.add(:base, "The requested number of #{event_ticket} tickets are not available")
        event_ticket_selections.find { |ets| ets.event_ticket == event_ticket }.errors.add(:quantity, "not available")
      end
    end

    # Validate the same registrant user isn't being registered twice
    validate(if: -> { current_step == :details }) do
      present_event_registrants.group_by { |er| [er.user, er.event_ticket] }.each do |(user, event_ticket), event_registrants|
        if user.present? && event_registrants.length > 1
          errors.add(:base, "Unable to register #{user} for #{event_ticket} more than once")
          event_registrants.each { |er| er.errors.add(:user_id, "cannot be registered for #{event_ticket} more than once") }
        end
      end
    end

    # Validate the same registrant user isn't registered on another registration
    validate(if: -> { current_step == :details }) do
      present_event_registrants.select { |er| er.user.present? }.each do |er|
        existing = Effective::EventRegistrant.unarchived.registered.where(event_ticket: er.event_ticket, user: er.user).where.not(id: er)

        if existing.present?
          errors.add(:base, "Unable to register #{er.user} for #{er.event_ticket}. They've already been registered")
          er.errors.add(:user_id, "Unable to register #{er.user} for #{er.event_ticket}. They've already been registered")
        end
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

      with_addons = event.event_products.any? { |event_product| event_product.archived? == false }

      with_addons ? wizard_step_keys : (wizard_step_keys - [:addons])
    end

    def delayed_payment_attributes
      { delayed_payment: event&.delayed_payment, delayed_payment_date: event&.delayed_payment_date }
    end

    def delayed_payment_date_upcoming?
      event&.delayed_payment_date_upcoming?
    end

    def find_or_build_submit_fees
      with_outstanding_coupon_fees(submit_fees)
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

  def display_countdown?
    return false if done?
    return false unless selected_at.present?
    return false unless current_step.present?

    [:start, :tickets, :submitted, :complete].exclude?(current_step)
  end

  # When we make a ticket selection, we assign the selected_at to all tickets
  # So the max or the min should be the same here.
  def selected_at
    event_registrants.map(&:selected_at).compact.max
  end

  def selected_expires_at
    selected_at + EffectiveEvents.EventRegistration.selection_window
  end

  def selected_expired?
    return false if selected_at.blank?
    Time.zone.now >= selected_expires_at
  end

  def selection_not_expired?
    return true if selected_at.blank?
    Time.zone.now < selected_expires_at
  end

  # Called by a before_action on the event registration show action
  def ticket_selection_expired!
    raise("unexpected submitted registration") if was_submitted?
    raise("unexpected purchased order") if submit_order&.purchased?
    raise("unexpected deferred order") if submit_order&.deferred?

    event_registrants.each { |er| er.assign_attributes(selected_at: nil) }
    event_ticket_selections.each { |ets| ets.assign_attributes(quantity: 0) }
    assign_attributes(current_step: nil, wizard_steps: {}) # Reset all steps

    save!
  end

  # This considers the event_ticket_selection and builds the appropriate event_registrants
  def update_event_registrants
    event_ticket_selections.each do |event_ticket_selection|
      event_ticket = event_ticket_selection.event_ticket
      quantity = event_ticket_selection.quantity.to_i

      # All the registrants for this event ticket
      registrants = event_registrants.select { |er| er.event_ticket == event_ticket }

      # Delete over quantity
      if (diff = registrants.length - quantity) > 0
        registrants.last(diff).each { |er| er.mark_for_destruction }
      end

      # Create upto quantity
      if (diff = quantity - registrants.length) > 0
        diff.times { build_event_registrant(event_ticket: event_ticket) }
      end
    end

    event_registrants
  end

  # Assigns the selected at time to start the reservation window
  def select_event_registrants
    now = Time.zone.now
    present_event_registrants.each { |er| er.assign_attributes(selected_at: now) }
  end

  # Looks at any unselected event registrants and assigns a waitlist value
  def waitlist_event_registrants
    present_event_registrants.group_by { |er| er.event_ticket }.each do |event_ticket, event_registrants|
      if event_ticket.waitlist?
        capacity = event.capacity_available(event_ticket: event_ticket, event_registration: self)
        event_registrants.each_with_index { |er, index| er.assign_attributes(waitlisted: index >= capacity) }
      else
        event_registrants.each { |er| er.assign_attributes(waitlisted: false) }
      end
    end
  end

  def tickets!
    assign_attributes(current_step: :tickets) # Ensure the unavailable tickets validations are run

    reset_all_wizard_steps_after(:tickets) unless was_submitted?

    update_event_registrants
    select_event_registrants
    waitlist_event_registrants

    after_commit do
      update_submit_fees_and_order! if submit_order.present?
      update_deferred_event_registration! if submit_order&.deferred?
    end

    save!
  end

  def details!
    after_commit do
      update_submit_fees_and_order! if submit_order.present?
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

  def build_event_registrant(event_ticket:)
    event_registrants.build(event: event, event_ticket: event_ticket, owner: owner)
  end

  # Find or build - # Used for testing
  # def event_registrant(event_ticket:, first_name:, last_name:, email:)
  #   registrant = event_registrants.find { |er| er.event_ticket == event_ticket && er.first_name == first_name && er.last_name == last_name && er.email == email }
  #   registrant || event_registrants.build(event: event, event_ticket: event_ticket, owner: owner, first_name: first_name, last_name: last_name, email: email)
  # end

  # Find or build. But it's not gonna work with more than 1. This is for testing only really.
  def event_addon(event_product:, first_name:, last_name:, email:)
    addon = event_addons.find { |er| er.event_product == event_product && er.first_name == first_name && er.last_name == last_name && er.email == email }
    addon || event_addons.build(event: event, event_product: event_product, owner: owner, first_name: first_name, last_name: last_name, email: email)
  end

  # Find or build
  def event_ticket_selection(event_ticket:, quantity: 0)
    selection = event_ticket_selections.find { |ets| ets.event_ticket == event_ticket } 
    selection || event_ticket_selections.build(event_ticket: event_ticket, quantity: quantity)
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
      unavailable << event_ticket unless event.event_ticket_available?(event_ticket, except: self, quantity: event_tickets.length)
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

    assign_attributes(current_step: :details) if current_step.blank? # Enables validations
    save!

    update_submit_fees_and_order! if submit_order.present? && !submit_order.purchased?

    true
  end

  private

  def update_deferred_event_registration!
    raise('expected a deferred submit order') unless submit_order&.deferred?

    # Mark registered anyone who hasn't been registered yet. They are now!
    event_registrants.reject(&:registered?).each { |event_registrant| event_registrant.registered! }

    true
  end

  def present_event_registrants
    event_registrants.reject(&:marked_for_destruction?).reject(&:archived?)
  end

  def present_event_addons
    event_addons.reject(&:marked_for_destruction?).reject(&:archived?)
  end

end
