# frozen_string_literal: true

module Effective
  class Event < ActiveRecord::Base
    self.table_name = (EffectiveEvents.events_table_name || :events).to_s

    if defined?(PgSearch)
      include PgSearch::Model
      multisearchable against: [:title, :body]
    end

    has_many :event_tickets, -> { EventTicket.sorted }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_tickets, allow_destroy: true

    has_many :event_products, -> { EventProduct.sorted }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_products, allow_destroy: true

    has_many :event_registrants, -> { order(:event_ticket_id, :id) }, inverse_of: :event
    accepts_nested_attributes_for :event_registrants, allow_destroy: true

    has_many :event_addons, -> { order(:event_product_id).order(:id) }, inverse_of: :event
    accepts_nested_attributes_for :event_addons, allow_destroy: true

    has_many :event_notifications, -> { order(:id) }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_notifications, allow_destroy: true

    # Used by the registration_available checks
    has_many :registered_event_registrants, -> { EventRegistrant.registered.unarchived }, class_name: 'Effective::EventRegistrant', inverse_of: :event
    has_many :registered_event_addons, -> { EventAddon.registered.unarchived }, class_name: 'Effective::EventAddon', inverse_of: :event

    # rich_text_body - Used by the select step
    has_many_rich_texts

    # rich_text_body
    # rich_text_excerpt
    # rich_text_confirmation_email

    # rich_text_all_steps_content
    # rich_text_start_content
    # rich_text_select_content
    # rich_text_select_content

    has_one_attached :file

    acts_as_role_restricted if respond_to?(:acts_as_role_restricted)
    acts_as_published
    acts_as_slugged
    acts_as_tagged if respond_to?(:acts_as_tagged)
    log_changes if respond_to?(:log_changes)

    attr_accessor :mailer_preview # Set by the mailer preview. Disabled delayed payment validations

    effective_resource do
      title                  :string

      category               :string
      slug                   :string

      published_start_at       :datetime
      published_end_at         :datetime
      legacy_draft             :boolean       # No longer used. To be removed.

      start_at               :datetime
      end_at                 :datetime

      registration_start_at  :datetime
      registration_end_at    :datetime

      early_bird_end_at      :datetime  # Optional

      external_registration       :boolean
      external_registration_url   :string

      allow_blank_registrants     :boolean

      # Delayed Payments feature
      delayed_payment             :boolean
      delayed_payment_date        :date

      # Access
      roles_mask             :integer
      authenticate_user      :boolean

      timestamps
    end

    scope :sorted, -> { order(start_at: :desc) }

    scope :for_sitemap, -> { published }

    scope :deep, -> { 
      base = includes(:event_registrants, :event_tickets, :rich_texts) 
      base = base.includes(:pg_search_document) if defined?(PgSearch)
      base
    }

    scope :upcoming, -> { where(arel_table[:end_at].gt(Time.zone.now)) }
    scope :past, -> { where(arel_table[:end_at].lteq(Time.zone.now)) }

    scope :closed, -> { where(arel_table[:registration_end_at].lt(Time.zone.now)) }
    scope :not_closed, -> { where(arel_table[:registration_end_at].gteq(Time.zone.now)) }

    scope :with_tickets, -> { where(id: Effective::EventTicket.select('event_id')) }

    # Doesnt consider sold out yet
    scope :registerable, -> { published.not_closed.with_tickets }
    scope :external, -> { published.where(external_registration: true) }

    scope :paginate, -> (page: nil, per_page: nil) {
      page = (page || 1).to_i
      offset = [(page - 1), 0].max * (per_page || EffectiveEvents.per_page)

      limit(per_page).offset(offset)
    }

    scope :events, -> (user: nil, category: nil, unpublished: false) {
      scope = all.deep

      # We include member only events for all users
      # if defined?(EffectiveRoles) && EffectiveEvents.use_effective_roles
      #   scope = scope.for_role(user&.roles)
      # end

      if category.present?
        scope = scope.where(category: category)
      end

      unless unpublished
        scope = scope.published
      end

      scope
    }

    scope :delayed, -> { where(delayed_payment: true).where.not(delayed_payment_date: nil) }
    scope :delayed_payment_date_past, -> { delayed.where(arel_table[:delayed_payment_date].lteq(Time.zone.today)) }
    scope :delayed_payment_date_upcoming, -> { delayed.where(arel_table[:delayed_payment_date].gt(Time.zone.today)) }

    validates :title, presence: true, length: { maximum: 255 }
    validates :start_at, presence: true
    validates :end_at, presence: true
    validates :external_registration_url, url: true

    validates :delayed_payment, inclusion: { in: [false], message: "cannot be used for external registration events" }, if: -> { external_registration? }
    validates :delayed_payment_date, presence: true, if: -> { delayed_payment? }
    validates :delayed_payment_date, absence: true, unless: -> { delayed_payment? }
    validates :slug, exclusion: { in: Array(EffectiveEvents.categories) + ['past'], message: "must not match a category name or past" }

    validate(if: -> { start_at && end_at }) do
      errors.add(:end_at, 'must be after start date') unless start_at < end_at
    end

    validate(if: -> { start_at && registration_start_at }) do
      errors.add(:registration_start_at, 'must be before start date') unless registration_start_at < start_at
    end

    validate(if: -> { registration_start_at && registration_end_at }) do
      errors.add(:registration_end_at, 'must be after start registration date') unless registration_start_at < registration_end_at
    end

    validate(if: -> { start_at && early_bird_end_at }) do
      errors.add(:early_bird_end_at, 'must be before start date') unless early_bird_end_at < start_at
    end

    validate(if: -> { delayed_payment? }) do
      errors.add(:delayed_payment, 'no delayed payment processor available') unless EffectiveOrders.try(:delayed?) || mailer_preview
    end

    validate(if: -> { file.attached? }) do
      errors.add(:file, 'must be an image') unless file.image?
    end

    validate(if: -> { category.present? }) do
      errors.add(:category, 'is not included in the list') unless EffectiveEvents.categories.include?(category)
    end

    validate(if: -> { persisted? && delayed_payment_changed? && delayed_payment_was && !delayed_payment? }) do
      errors.add(:delayed_payment, "cannot be disabled because there are existing delayed orders") if delayed_orders.present?
    end

    after_commit(if: -> { persisted? && delayed? && delayed_payment_date_previously_changed? }) do
      update_delayed_orders_delayed_payment_date!
    end

    def to_s
      title.presence || model_name.human
    end

    def body
      rich_text_body
    end

    def excerpt
      rich_text_excerpt
    end

    def any_waitlist?
      event_tickets.any? { |et| et.waitlist? }
    end

    # No longer includes sold_out? we check that separately
    def registerable?
      return false unless published?
      return false unless registration_available?
      (external_registration? && external_registration_url.present?) || event_tickets.present?
    end

    def registerable_when_impersonating?
      (external_registration? && external_registration_url.present?) || event_tickets.present?
    end

    def registration_available?
      return false if closed?

      return false if registration_start_at.blank?
      registration_start_at <= Time.zone.now
    end

    def closed?
      return false if registration_end_at.blank?
      registration_end_at < Time.zone.now
    end

    def sold_out?(except: nil)
      raise('expected except to be an EventRegistration') if except && !except.class.try(:effective_events_event_registration?)

      return false unless event_tickets.present?
      return false if any_waitlist?

      event_tickets.none? { |event_ticket| event_ticket_available?(event_ticket, except: except, quantity: 1) }
    end

    def waitlist_only?
      any_waitlist? && event_tickets.none? { |et| et.capacity_available > 0 }
    end

    def upcoming?
      end_at > Time.zone.now
    end

    def past?
      end_at < Time.zone.now
    end

    def early_bird?
      return false if early_bird_end_at.blank?
      early_bird_end_at > Time.zone.now
    end

    def early_bird_past?
      return false if early_bird_end_at.blank?
      early_bird_end_at <= Time.zone.now
    end

    def early_bird_status
      if early_bird?
        'Early Bird Pricing'
      elsif early_bird_past?
        'Expired'
      else
        'None'
      end
    end

    # Returns a duplicated event object, or throws an exception
    def duplicate
      Event.new(attributes.except('id', 'updated_at', 'created_at')).tap do |event|
        event.title = event.title + ' (Copy)'
        event.slug = event.slug + '-copy'

        event.rich_text_body = rich_text_body
        event.rich_text_excerpt = rich_text_excerpt

        event.assign_attributes(published_start_at: nil, published_end_at: nil)
      end
    end

    def duplicate!
      duplicate.tap { |event| event.save! }
    end

    def start_time
      start_at
    end

    # The amount of tickets that can be purchased except ones from an event registration
    def capacity_selectable(event_ticket:, event_registration: nil)
      return 0 if event_ticket.archived?
      return 100 if event_ticket.capacity.blank?
      return 100 if event_ticket.waitlist?

      event_ticket.capacity_selectable(except: event_registration)
    end

    # The amount of tickets that can be purchased except ones from an event registration
    def capacity_available(event_ticket:, event_registration: nil)
      event_ticket.capacity_available(except: event_registration)
    end

    # Just used in tests so far
    def capacity_taken(event_ticket:, event_registration: nil)
      event_ticket.capacity_taken(except: event_registration)
    end

    # Can I register/purchase this many new event tickets?
    def event_ticket_available?(event_ticket, except: nil, quantity: 1)
      raise('expected an EventTicket') unless event_ticket.kind_of?(Effective::EventTicket)
      raise('expected except to be an EventRegistration') if except && !except.class.try(:effective_events_event_registration?)
      raise('expected quantity to be greater than 0') unless quantity.to_i > 0

      return false if event_ticket.archived?
      return true if event_ticket.capacity.blank? # No capacity enforced
      return true if event_ticket.waitlist?       # Always available for waitlist

      # Do we have any tickets available left?
      event_ticket.capacity_available(except: except) >= quantity.to_i
    end

    # Can I register/purchase this many new event products?
    def event_product_available?(event_product, quantity: 1)
      raise('expected an EventProduct') unless event_product.kind_of?(Effective::EventProduct)
      raise('expected quantity to be greater than 0') unless quantity.to_i > 0

      return false if event_product.archived?
      return true if event_product.capacity.blank?   # No capacity enforced for this product

      # Total number already sold
      registered = registered_event_addons.count { |r| r.event_product_id == event_product.id }

      # If there's capacity for this many more
      (registered + quantity) <= event_product.capacity
    end

    def delayed?
      delayed_payment? && delayed_payment_date.present?
    end

    def delayed_payment_date_upcoming?
      return false unless delayed?
      delayed_payment_date > Time.zone.now.to_date
    end

    def update_delayed_orders_delayed_payment_date!
      raise('expected delayed payment date to be present') unless delayed_payment_date.present?

      transaction do
        delayed_orders.find_each { |order| order.update!(delayed_payment_date: delayed_payment_date) }
      end
    end

    # When an event payment date is changed, all pending orders should also be updated
    def delayed_orders
      order_ids = (
        Effective::OrderItem.where(purchasable_id: event_registrants, purchasable_type: 'Effective::EventRegistrant').pluck(:order_id) +
        Effective::OrderItem.where(purchasable_id: event_addons, purchasable_type: 'Effective::EventAddon').pluck(:order_id)
      ).uniq

      Effective::Order.where.not(status: [:purchased, :declined, :voided]).delayed.where(id: order_ids) # deferred delayed orders
    end

    def qb_item_names
      (event_tickets + event_products).map(&:qb_item_name).uniq - ['', nil]
    end
  end
end
