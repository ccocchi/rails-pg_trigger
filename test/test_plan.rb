# frozen_string_literal: true

require "test_helper"

class TestPlan < Minitest::Test
  attr_reader :plan

  def setup
    @plan = PgTrigger::Plan.new
    @trigger = nil
  end

  def test_empty_by_default
    assert plan.empty?
  end

  def test_adding_trigger
    plan.add_trigger(trigger)

    assert_equal :create, plan.type
    assert_equal "users", plan.table
    refute plan.empty?
    assert_plan_has_actions :to_add
    assert_equal [trigger], plan.new_triggers
  end

  def test_adding_triggers_on_same_table
    other = PgTrigger::Trigger.new.on("users").before(:update)

    plan.add_trigger(trigger)
    plan.add_trigger(other)

    assert_equal :create, plan.type
    assert_equal "users", plan.table
    assert_plan_has_actions :to_add
  end

  def test_dropping_trigger
    plan.drop_trigger(trigger)

    assert_equal :drop, plan.type
    assert_equal "users", plan.table
    refute plan.empty?
    assert_plan_has_actions :to_remove
  end

  def test_mixing_adds_and_drops
    plan.add_trigger(trigger)
    plan.drop_trigger(PgTrigger::Trigger.new.on("comments"))

    assert_equal :multi, plan.type
    assert_equal "multiple", plan.table
    assert_plan_has_actions :to_add
    assert_plan_has_actions :to_remove
  end

  def test_mixing_adds_and_drops_on_same_table
    plan.add_trigger(trigger)
    plan.drop_trigger(trigger)

    assert_equal :multi, plan.type
    assert_equal "users", plan.table
  end

  def test_mixing_tables
    plan.add_trigger(trigger)
    plan.add_trigger(PgTrigger::Trigger.new.on("comments").after(:insert))

    assert_equal :create, plan.type
    assert_equal "multiple", plan.table
  end

  def test_updating_trigger
    plan.update_trigger(trigger, trigger)

    assert_equal :update, plan.type
    assert_equal "users", plan.table
    assert_plan_has_actions :to_add
    assert_plan_has_actions :to_remove
  end

  def test_name_on_trigger_create
    plan.add_trigger(trigger)
    assert_equal "create_triggers_on_users", plan.name
  end

  def test_name_on_trigger_drop
    plan.drop_trigger(trigger)
    assert_equal "drop_triggers_on_users", plan.name
  end

  def test_name_on_trigger_update
    plan.update_trigger(trigger, trigger)
    assert_equal "update_triggers_on_users", plan.name
  end

  private

  def trigger
    @trigger ||= PgTrigger::Trigger.new.on("users").after(:insert)
  end

  def assert_plan_has_actions(type)
    assert @plan.actions.key?(type)
  end
end
