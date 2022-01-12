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

    def all_wizard_steps
      const_get(:WIZARD_STEPS).keys
    end

    def required_wizard_steps
      [:start, :summary, :billing, :checkout, :submitted]
    end
  end

  included do
    acts_as_purchasable_parent
    acts_as_tokened

    acts_as_statused(
      :draft,      # Just Started
      :submitted   # All done
    )

    acts_as_wizard(
      start: 'Start',
      registrants: 'Registrants',
      purchases: 'Purchases',
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
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

    has_many :event_purchases, -> { order(:id) }, class_name: 'Effective::EventPurchase', inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_purchases, reject_if: :all_blank, allow_destroy: true

    has_many :orders, -> { order(:id) }, as: :parent, class_name: 'Effective::Order', dependent: :nullify
    accepts_nested_attributes_for :orders

    effective_resource do
      # Acts as Statused
      status                 :string, permitted: false
      status_steps           :text, permitted: false

      # Dates
      submitted_at           :datetime

      # Acts as Wizard
      wizard_steps           :text, permitted: false

      timestamps
    end

    scope :deep, -> { includes(:owner, :event, :event_registrants) }
    scope :sorted, -> { order(:id) }

    scope :in_progress, -> { where.not(status: [:submitted]) }
    scope :done, -> { where(status: [:submitted]) }

    scope :for, -> (user) { where(owner: user) }

    # All Steps validations
    validates :owner, presence: true
    validates :event, presence: true

    # Registrants Step
    validate(if: -> { current_step == :registrants }) do
      self.errors.add(:event_registrants, "can't be blank") unless present_event_registrants.present?
    end

    def required_steps
      return self.class.test_required_steps if Rails.env.test? && self.class.test_required_steps.present?
      event&.event_products.present? ? wizard_step_keys : (wizard_step_keys - [:purchases])
    end

    # All Fees and Orders
    def submit_fees
      (event_registrants + event_purchases)
    end

  end

  # Instance Methods
  def to_s
    persisted? ? "Registration ##{id}" : 'Event Registration'
  end

  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  # Find or build
  def event_registrant(first_name:, last_name:, email:)
    registrant = event_registrants.find { |er| er.first_name == first_name && er.last_name == last_name && er.email == email }
    registrant || event_registrants.build(event: event, owner: owner, first_name: first_name, last_name: last_name, email: email)
  end

  # This builds the default event registrants used by the wizard form
  def build_event_registrants
    if event_registrants.blank?
      raise('expected owner and event to be present') unless owner && event
      event_registrants.build(
        first_name: owner.try(:first_name),
        last_name: owner.try(:last_name),
        email: owner.try(:email)
      )
    end

    event_registrants
  end

  private

  def present_event_registrants
    event_registrants.reject(&:marked_for_destruction?)
  end

end
