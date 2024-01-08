# frozen_string_literal: true

require "test_helper"

class TestPlanBuilder < Minitest::Test
  def test_plan_building_no_triggers
    plan = PgTrigger::Plan::Builder.new([], {}).result
    assert_empty plan
  end

  def test_plan_building_no_changes
    trigger = PgTrigger::Trigger.new.on("comments").after(:insert) { "SELECT 1;" }
    existing = { trigger.name => trigger.content }

    plan = PgTrigger::Plan::Builder.new([trigger], existing).result

    assert_empty plan
  end

  def test_plan_building_new_triggers
    trigger = PgTrigger::Trigger.new.on("comments").after(:insert) { "SELECT 1;" }
    plan = PgTrigger::Plan::Builder.new([trigger], {}).result

    refute_empty plan
    assert_equal [trigger], plan.new_triggers
    assert_empty plan.removed_triggers
  end

  def test_plan_building_remove_triggers
    existing = { "comments_after_insert_tr" => "SELECT 1;" }
    plan = PgTrigger::Plan::Builder.new([], existing).result

    refute_empty plan
    assert_empty plan.new_triggers
    assert_equal ["comments_after_insert_tr"], plan.removed_triggers
  end

  def test_plan_building_update_triggers
    trigger = PgTrigger::Trigger.new.on("comments").after(:insert) { "SELECT 1;" }
    existing = { trigger.name => "SELECT 2;" }

    plan = PgTrigger::Plan::Builder.new([trigger], existing).result

    refute_empty plan
    assert_equal [trigger], plan.new_triggers
    assert_equal ["comments_after_insert_tr"], plan.removed_triggers
  end
end
