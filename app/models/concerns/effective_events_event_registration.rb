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
      [:start, :registrants, :summary, :billing, :checkout, :submitted]
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
      summary: 'Review',
      billing: 'Billing Address',
      checkout: 'Checkout',
      submitted: 'Submitted'
    )

    log_changes(except: :wizard_steps) if respond_to?(:log_changes)

    # Application Namespace
    belongs_to :owner, polymorphic: true
    accepts_nested_attributes_for :owner

    # Effective Namespace
    belongs_to :event

    has_many :event_registrants, -> { order(:id) }, inverse_of: :event_registration, dependent: :destroy
    accepts_nested_attributes_for :event_registrants, reject_if: :all_blank, allow_destroy: true

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

    # All Steps validations
    validates :owner, presence: true
    validates :event, presence: true

    # Billing Step
    validate(if: -> { current_step == :billing && owner.present? }) do
      self.errors.add(:base, "must have a billing address") unless owner.billing_address.present?
      self.errors.add(:base, "must have an email") unless owner.email.present?
    end

    after_purchase do |_|
      raise('expected submit_order to be purchased') unless submit_order&.purchased?
      submit_purchased!
      after_submit_purchased!
    end
  end

  # Instance Methods
  def to_s
    'Event Registration'
  end

  def in_progress?
    draft?
  end

  def done?
    submitted?
  end

  def can_visit_step?(step)
    can_revisit_completed_steps(step)
  end

  # All Fees and Orders
  def submit_fees
    event_registrants
  end

  def submit_order
    orders.first
  end

  def find_or_build_submit_fees
    return submit_fees if submit_fees.present?

    fees.build(
      owner: owner,
      fee_type: 'Applicant',
      category: category,
      price: category.applicant_fee
    )

    submit_fees
  end

  def find_or_build_submit_order
    order = submit_order || orders.build(user: owner)
    fees = submit_fees()

    # Adds fees, but does not overwrite any existing price.
    fees.each do |fee|
      order.add(fee) unless order.purchasables.include?(fee)
    end

    order.purchasables.each do |purchasable|
      order.remove(purchasable) unless fees.include?(purchasable)
    end

    # From Billing Step
    order.billing_address = owner.billing_address if owner.billing_address.present?

    order
  end

  # Should be indempotent.
  def build_submit_fees_and_order
    return false if was_submitted?

    fees = find_or_build_submit_fees()
    raise('already has purchased submit fees') if fees.any? { |fee| fee.purchased? }

    order = find_or_build_submit_order()
    raise('already has purchased submit order') if order.purchased?

    true
  end

  # Owner clicks on the Billing step. Next step is Checkout
  def billing!
    ready!
  end

  # Ready to check out
  def ready!
    build_submit_fees_and_order
    save!
  end

  # Called automatically via after_purchase hook above
  def submit_purchased!
    return false if was_submitted?

    wizard_steps[:checkout] = Time.zone.now
    submit!
  end

  # A hook to extend
  def after_submit_purchased!
  end

  # Draft -> Submitted requirements
  def submit!
    raise('already submitted') if was_submitted?
    raise('expected a purchased order') unless submit_order&.purchased?

    wizard_steps[:checkout] ||= Time.zone.now
    wizard_steps[:submitted] = Time.zone.now
    submitted!
  end

end
