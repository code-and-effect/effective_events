EffectiveEvents.setup do |config|
  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Event Settings
  # config.event_registration_class_name = 'Effective::EventRegistration'

  # Pagination length on the Events#index page
  config.per_page = 10

  # Events can be restricted by role
  config.use_effective_roles = true

  # Create effective_memberships organizations from the Ticket Details screen.
  config.organization_enabled = false

  # Categories
  config.categories = ['Events']

  # Hint text for event images attachments
  config.events_hint_text = 'Optional. Shown on the events index and event pages. Dimensions are 220px tall and 350px wide.'

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
  # config.mailer_froms = nil       # Default Froms collection
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject

  # We always use effective email templates for event notifications
end
