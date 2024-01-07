# frozen_string_literal: true

require "test_helper"

class TestTriggerClass < Minitest::Test
  attr_reader :trigger

  def setup
    @trigger = PgTrigger::Trigger.new
  end

  def test_on
    trigger.on("users")
    assert_equal "users", trigger.table
  end

  def test_after
    trigger.after(:insert, :update)

    assert_equal :after, trigger.timing
    assert_equal [:insert, :update], trigger.events
  end

  def test_before
    trigger.before(:delete)

    assert_equal :before, trigger.timing
    assert_equal [:delete], trigger.events
  end

  def test_after_events_aliases
    trigger.after(:create, :destroy)
    assert_equal [:insert, :delete], trigger.events
  end

  def test_before_events_aliases
    trigger.before(:create, :destroy)
    assert_equal [:insert, :delete], trigger.events
  end

  def test_of
    trigger.of(:id, :created_at)
    assert_equal [:id, :created_at], trigger.columns
  end

  def test_named
    trigger.named("users_after_insert_tr")
    assert_equal "users_after_insert_tr", trigger.name
  end

  def test_inferred_name
    trigger.on("users").before(:insert, :update)
    assert_equal "users_before_insert_or_update_tr", trigger.name
  end

  def test_chaining
    trigger.after(:update).of(:a, :b) { "SQL" }

    assert_equal :after, trigger.timing
    assert_equal [:update], trigger.events
    assert_equal [:a, :b], trigger.columns
    assert_equal "SQL", trigger.content
  end

  def test_create_function_sql
    content = "UPDATE posts SET comments_count = comments_count + 1"
    trigger.on("comments").after(:insert).named("foo_tr") { content }

    sql = trigger.create_function_sql

    assert_match %r{CREATE OR REPLACE FUNCTION foo_tr\(\) RETURNS TRIGGER}, sql
    assert_match %r{BEGIN\s+#{Regexp.escape(content)};\s+RETURN NULL;\s+END}, sql
  end

  def test_drop_function_sql
    trigger.named("foo_tr")
    assert_equal "DROP FUNCTION IF EXISTS foo_tr;", trigger.drop_function_sql
  end

  def test_create_trigger_sql
    trigger.on("comments").after(:insert, :update).named("foo_tr")
    expected = <<~SQL
      CREATE TRIGGER foo_tr
      AFTER INSERT OR UPDATE ON "comments"
      FOR EACH ROW
      EXECUTE FUNCTION foo_tr();
    SQL

    assert_equal expected, trigger.create_trigger_sql
  end
end
