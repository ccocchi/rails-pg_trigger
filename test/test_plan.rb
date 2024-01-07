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
  end

  def test_adding_triggers_on_same_table
    other = PgTrigger::Trigger.new.on("users").before(:update)

    plan.add_trigger(trigger)
    plan.add_trigger(other)

    assert_equal :create, plan.type
    assert_equal "users", plan.table
    assert_plan_has_actions :to_add
  end

  def test_dropping_trigger_by_name
    plan.drop_trigger_by_name("foo_tr")

    assert_equal :drop, plan.type
    refute plan.empty?
    assert_plan_has_actions :to_remove
  end

  def test_mixing_adds_and_drops
    plan.add_trigger(trigger)
    plan.drop_trigger_by_name("foo_tr")

    assert_equal :multi, plan.type
    assert_equal "users", plan.table # meh
    assert_plan_has_actions :to_add
    assert_plan_has_actions :to_remove
  end

  def test_updating_trigger
    plan.update_trigger(trigger)

    assert_equal :update, plan.type
    assert_equal "users", plan.table
    assert_plan_has_actions :to_add
    assert_plan_has_actions :to_remove
  end

  private

  def trigger
    @trigger ||= PgTrigger::Trigger.new.on("users").after(:insert)
  end

  def assert_plan_has_actions(type)
    assert @plan.instance_variable_get(:@actions).key?(type)
  end
end
