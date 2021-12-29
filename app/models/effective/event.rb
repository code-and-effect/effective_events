# frozen_string_literal: true

# TODO
# [ ] validate end_at is before start_at

module Effective
  class Event < ActiveRecord::Base

    has_many :event_registrants
    has_many :event_tickets

    has_rich_text :body
    log_changes if respond_to?(:log_changes)

    accepts_nested_attributes_for :event_registrants
    accepts_nested_attributes_for :event_tickets

    effective_resource do
      title                  :string
      body                   :string

      start_at               :datetime
      end_at                 :datetime
      registration_start_at  :datetime
      registration_end_at    :datetime
      early_bird_end_at      :datetime

      timestamps
    end

    scope :sorted, -> { order(:end_at) }
    scope :deep, -> { all }

    validates :title, presence: true
    validates :end_at, presence: true
    validates :start_at, presence: true
    validates :registration_start_at, presence: true
    validates :registration_end_at, presence: true
    validates :early_bird_end_at, presence: true

    def to_s
      title.presence || 'New Event'
    end

    def closed?
      return false if registration_end_at.blank?
      registration_end_at < Time.zone.now
    end

    def early_bird?
      return false if early_bird_end_at.blank?
      early_bird_end_at < Time.zone.now
    end

  end
end
