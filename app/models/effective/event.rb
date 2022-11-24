# frozen_string_literal: true

module Effective
  class Event < ActiveRecord::Base
    has_many :event_tickets, -> { EventTicket.sorted }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_tickets, allow_destroy: true

    has_many :event_products, -> { EventProduct.sorted }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_products, allow_destroy: true

    has_many :event_registrants, -> { order(:event_ticket_id, :created_at) }, inverse_of: :event
    accepts_nested_attributes_for :event_registrants, allow_destroy: true

    has_many :event_addons, -> { order(:event_product_id, :created_at) }, inverse_of: :event
    accepts_nested_attributes_for :event_addons, allow_destroy: true

    has_many :event_notifications, -> { order(:id) }, inverse_of: :event, dependent: :destroy
    accepts_nested_attributes_for :event_notifications, allow_destroy: true

    # rich_text_body - Used by the select step
    has_many_rich_texts

    # rich_text_body
    # rich_text_excerpt

    # rich_text_all_steps_content
    # rich_text_start_content
    # rich_text_select_content
    # rich_text_select_content

    has_one_attached :file

    acts_as_slugged
    log_changes if respond_to?(:log_changes)
    acts_as_role_restricted if respond_to?(:acts_as_role_restricted)

    self.table_name = EffectiveEvents.events_table_name.to_s

    effective_resource do
      title                  :string

      category               :string
      slug                   :string

      draft                  :boolean
      published_at           :datetime

      start_at               :datetime
      end_at                 :datetime

      registration_start_at  :datetime
      registration_end_at    :datetime

      early_bird_end_at      :datetime  # Optional

      external_registration       :boolean
      external_registration_url   :string

      # Access
      roles_mask             :integer
      authenticate_user      :boolean

      timestamps
    end

    scope :sorted, -> { order(start_at: :desc) }
    scope :deep, -> { includes(:event_registrants, :event_tickets) }

    scope :published, -> { where(draft: false).where(arel_table[:published_at].lt(Time.zone.now)) }
    scope :unpublished, -> { where(draft: true).where(arel_table[:published_at].gteq(Time.zone.now)) }

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

      if defined?(EffectiveRoles) && EffectiveEvents.use_effective_roles
        scope = scope.for_role(user&.roles)
      end

      if user.blank?
        scope = scope.where(authenticate_user: false)
      end

      if category.present?
        scope = scope.where(category: category)
      end

      unless unpublished
        scope = scope.published
      end

      scope
    }

    validates :title, presence: true, length: { maximum: 255 }
    validates :published_at, presence: true, unless: -> { draft? }
    validates :start_at, presence: true
    validates :end_at, presence: true

    validates :registration_start_at, presence: true, unless: -> { external_registration? }
    validates :registration_end_at, presence: true, unless: -> { external_registration? }
    validates :external_registration_url, presence: true, if: -> { external_registration? }

    validate(if: -> { start_at && end_at }) do
      self.errors.add(:end_at, 'must be after start date') unless start_at < end_at
    end

    validate(if: -> { start_at && registration_start_at }) do
      self.errors.add(:registration_start_at, 'must be before start date') unless registration_start_at < start_at
    end

    validate(if: -> { registration_start_at && registration_end_at }) do
      self.errors.add(:registration_end_at, 'must be after start registration date') unless registration_start_at < registration_end_at
    end

    validate(if: -> { start_at && early_bird_end_at }) do
      self.errors.add(:early_bird_end_at, 'must be before start date') unless early_bird_end_at < start_at
    end

    validate(if: -> { file.attached? }) do
      self.errors.add(:file, 'must be an image') unless file.image?
    end

    validate(if: -> { category.present? }) do
      self.errors.add(:category, 'is not included in the list') unless EffectiveEvents.categories.include?(category)
    end

    def to_s
      title.presence || 'New Event'
    end

    def body
      rich_text_body
    end

    def excerpt
      rich_text_excerpt
    end

    def published?
      return false if draft?
      return false if published_at.blank?

      published_at < Time.zone.now
    end

    def registerable?
      return false unless published?
      return false if closed?
      return false if sold_out?

      external_registration? || event_tickets.present?
    end

    def closed?
      return false if registration_end_at.blank?
      registration_end_at < Time.zone.now
    end

    def sold_out?
      false
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
        event.draft = true

        event.rich_text_body = rich_text_body
        event.rich_text_excerpt = rich_text_excerpt
      end
    end

    def duplicate!
      duplicate.tap { |event| event.save! }
    end

  end
end
