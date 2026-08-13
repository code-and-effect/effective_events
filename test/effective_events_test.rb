require "test_helper"

class EffectiveEventsTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert EffectiveEvents::VERSION
  end

  test "feature predicates require true" do
    with_config(organization_enabled: nil, code_of_conduct_enabled: 'true', validate_one_ticket_per_event: false) do
      assert_not EffectiveEvents.organization_enabled?
      assert_not EffectiveEvents.code_of_conduct_enabled?
      assert_not EffectiveEvents.validate_one_ticket_per_event?
    end

    with_config(code_of_conduct_enabled: true, validate_one_ticket_per_event: true) do
      assert EffectiveEvents.code_of_conduct_enabled?
      assert EffectiveEvents.validate_one_ticket_per_event?
    end
  end

  private

  def with_config(values)
    config = EffectiveEvents.config
    original = values.to_h { |key, _value| [key, config[key]] }
    values.each { |key, value| config[key] = value }
    yield
  ensure
    original.each { |key, value| config[key] = value }
  end
end
