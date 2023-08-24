require 'effective_resources'
require 'effective_events/engine'
require 'effective_events/version'

module EffectiveEvents

  def self.config_keys
    [
      :events_table_name, :event_registrants_table_name, :event_tickets_table_name,
      :event_registrations_table_name, :event_products_table_name, :event_addons_table_name, :event_notifications_table_name,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject, :use_effective_email_templates,
      :layout, :per_page, :use_effective_roles, :categories, :events_hint_text,
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

  def categories
    Array(config[:categories]) - [nil, false, '']
  end

end
