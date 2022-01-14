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
end
