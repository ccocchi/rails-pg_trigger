require "test_helper"

class TestPlanBuilder < Minitest::Test
  def setup
    @trigger = nil
  end

  def test_plan_building_no_triggers
    plan = PgTrigger::Plan::Builder.new([], []).result
    assert_empty plan
  end

  def test_plan_building_no_changes
    plan = PgTrigger::Plan::Builder.new([trigger], [trigger]).result

    assert_empty plan
  end

  def test_plan_building_new_triggers
    plan = PgTrigger::Plan::Builder.new([trigger], []).result

    refute_empty plan
    assert_equal [trigger], plan.new_triggers
    assert_empty plan.removed_triggers
  end

  def test_plan_building_remove_triggers
    plan = PgTrigger::Plan::Builder.new([], [trigger]).result

    refute_empty plan
    assert_empty plan.new_triggers
    assert_equal [trigger], plan.removed_triggers
  end

  def test_plan_building_update_triggers
    old = PgTrigger::Trigger.new.on("comments").after(:insert) { "SELECT 2;" }
    plan = PgTrigger::Plan::Builder.new([trigger], [old]).result

    refute_empty plan
    assert_equal [trigger], plan.new_triggers
    assert_equal [trigger], plan.removed_triggers
  end

  def trigger
    @trigger ||= PgTrigger::Trigger.new.on("comments").after(:insert) { "SELECT 1;" }
  end
end
