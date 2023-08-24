module Effective
  class EventRegistration < ActiveRecord::Base
    self.table_name = (EffectiveEvents.event_registrations_table_name || :event_registrations).to_s

    effective_events_event_registration
  end
end
