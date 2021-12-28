require 'effective_resources'
require 'effective_datatables'
require 'effective_events/engine'
require 'effective_events/version'

module EffectiveEvents

  def self.config_keys
    [:events_table_name, :layout]
  end

  include EffectiveGem

end
