require 'effective_resources'
require 'effective_events/engine'
require 'effective_events/version'

module EffectiveEvents

  def self.config_keys
    [
      :events_table_name, :event_registrants_table_name, :event_tickets_table_name, :event_ticket_selections_table_name,
      :event_registrations_table_name, :event_products_table_name, :event_addons_table_name, :event_notifications_table_name,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject,
      :layout, :per_page, :use_effective_roles, :organization_enabled, :categories, :events_hint_text,
      :event_registration_class_name
    ]
  end

  include EffectiveGem

  def self.EventRegistration
    event_registration_class_name&.constantize || Effective::EventRegistration
  end

  def self.mailer_class
    mailer&.constantize || Effective::EventsMailer
  end

  def self.categories
    Array(config[:categories]) - [nil, false, '']
  end

  def self.organization_enabled?
    organization_enabled == true
  end

  # If we can create delayed payment events at all
  def self.delayed?
    !!EffectiveOrders.try(:delayed?) 
  end

end
