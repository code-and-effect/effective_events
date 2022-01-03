EffectiveEvents.setup do |config|
  config.events_table_name = :events

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  config.per_page = 10

  config.use_effective_roles = true
end
