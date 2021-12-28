module EffectiveEvents
  class Engine < ::Rails::Engine
    engine_name 'effective_events'

    # Set up our default configuration options.
    initializer 'effective_events.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_events.rb")
    end

  end
end
