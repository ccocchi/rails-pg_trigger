# frozen_string_literal: true

require "test_helper"

class TestModel < Minitest::Test
  def teardown
    Comment.instance_variable_set :@_triggers, nil
  end

  def test_no_trigger
    assert_nil Comment._triggers
  end

  def test_one_trigger
    Comment.trigger.after(:insert) { "select 1;" }

    assert_instance_of Array, Comment._triggers
    tr = Comment._triggers.first
    assert_equal "comments", tr.table
  end

  def test_many_triggers
    Comment.trigger.after(:insert) { "select 1;" }
    Comment.trigger.before(:insert, :delete) { "select 3;"}

    assert_instance_of Array, Comment._triggers
    assert_equal 2, Comment._triggers.size
  end
end
