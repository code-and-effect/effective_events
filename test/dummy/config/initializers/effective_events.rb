EffectiveEvents.setup do |config|
  config.events_table_name = :events
  config.event_tickets_table_name = :event_tickets
  config.event_products_table_name = :event_products
  config.event_registrants_table_name = :event_registrants
  config.event_addons_table_name = :event_addons
  config.event_registrations_table_name = :event_registrations

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Event Settings
  # config.event_registrations_class_name = 'Effective::EventRegistration'

  # Pagination length on the Events#index page
  config.per_page = 10

  # Events can be restricted by role
  config.use_effective_roles = true

  # Mailer Configuration
  #
  # Additional mailer settings for parent_mailer, delivery_method, layout, sender and admin
  # are required fields in config/initializers/effective_resources.rb

  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::EventsMailer'

  # Use effective email templates for event notifications
  config.use_effective_email_templates = true
end
