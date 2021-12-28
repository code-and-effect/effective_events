# frozen_string_literal: true

module Effective
  class Event < ActiveRecord::Base
    log_changes if respond_to?(:log_changes)

    effective_resource do
      title         :string

      timestamps
    end

    scope :sorted, -> { order(:title) }
    scope :deep, -> { all }

    validates :title, presence: true

    def to_s
      title.presence || 'New Event'
    end

  end
end
