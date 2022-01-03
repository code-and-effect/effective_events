module EffectiveEvents
  class Engine < ::Rails::Engine
    engine_name 'effective_events'

    # Set up our default configuration options.
    initializer 'effective_events.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_events.rb")
    end

    # Include concern and allow any ActiveRecord object to call it
    initializer 'effective_events.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(EffectiveEventsEventRegistration::Base)
      end
    end

  end
end
