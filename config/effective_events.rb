EffectiveEvents.setup do |config|
  config.events_table_name = :events
  config.event_tickets_table_name = :event_tickets
  config.event_registrants_table_name = :event_registrants
  config.event_registrations_table_name = :event_registrations

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Event Settings
  # config.event_registrations_class_name = 'Effective::EventRegistration'

  config.per_page = 10

  config.use_effective_roles = true
end
