require 'effective_resources'
require 'effective_datatables'
require 'effective_orders'
require 'effective_events/engine'
require 'effective_events/version'

module EffectiveEvents

  def self.config_keys
    [
      :events_table_name, :event_registrants_table_name, :event_tickets_table_name,
      :layout, :per_page, :use_effective_roles
    ]
  end

  include EffectiveGem

end
