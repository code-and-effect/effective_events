require 'effective_resources'
require 'effective_events/engine'
require 'effective_events/version'

module EffectiveEvents

  def self.config_keys
    [
      :events_table_name, :event_registrants_table_name, :event_tickets_table_name, :event_ticket_selections_table_name,
      :event_registrations_table_name, :event_products_table_name, :event_addons_table_name, :event_notifications_table_name,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject,
      :layout, :per_page, :use_effective_roles, :categories, :events_hint_text,
      :organization_enabled, :create_users, :company_or_organization_required, :validate_one_ticket_per_event,
      :code_of_conduct_enabled, :code_of_conduct_slug,
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
    raise('missing the effective_memberships gem') if organization_enabled && !defined?(EffectiveMemberships)
    organization_enabled == true
  end

  def self.code_of_conduct_enabled?
    code_of_conduct_enabled == true
  end

  def self.code_of_conduct_effective_page
    return unless defined?(Effective::Page)
    Effective::Page.where(slug: code_of_conduct_slug).first
  end

  def self.code_of_conduct_effective_page!
    page = code_of_conduct_effective_page()
    raise("The Effective::Page for slug \"#{code_of_conduct_slug}\" does not exist. Please create it.") if page.blank?

    page
  end

  def self.validate_one_ticket_per_event?
    validate_one_ticket_per_event == true
  end

  # If we can create delayed payment events at all
  def self.delayed?
    !!EffectiveOrders.try(:delayed?) 
  end

end
