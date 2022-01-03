module Effective
  class EventRegistration < ActiveRecord::Base
    self.table_name = EffectiveEvents.event_registrations_table_name.to_s

    effective_events_event_registration
  end
end
