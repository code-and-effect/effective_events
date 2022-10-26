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

  # Categories
  config.categories = ['Events']

  # Hint text for event images attachments
  config.events_hint_text = 'Hint text that includes required image dimensions'

  # Mailer Settings
  # Please see config/initializers/effective_resources.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::EventsMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject

  # Use effective email templates for event notifications
  config.use_effective_email_templates = true
end
