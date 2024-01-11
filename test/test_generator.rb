require "test_helper"

class TestGenerator < Minitest::Test
  EXPECTATIONS_PATH = File.join(File.expand_path(__dir__), "expectations")

  def test_run_nothing_to_do
    result = PgTrigger::Generator.run(models: [Comment])
    assert_nil result
  end

  def test_run_adding_triggers
    result = PgTrigger::Generator.run(models: [Post, Comment])
    assert_path_exists File.join(MIGRATIONS_DIR, result)
  end

  def test_run_removing_triggers
    result = PgTrigger::Generator.run(models: [])
    assert_path_exists File.join(MIGRATIONS_DIR, result)
  end

  def test_generate_create_trigger
    plan = PgTrigger::Plan.new
    trigger = PgTrigger::Trigger.new.on("comments").after(:insert) do
      "UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id"
    end

    plan.add_trigger(trigger)
    migration = PgTrigger::Generator::Migration.new(plan)
    output = migration.generate_output

    assert_match %r{\d+_create_triggers_on_comments.rb}, migration.name
    assert_output_matches_file "create_triggers_on_comments.rb", output
  end

  def test_generate_drop_trigger
    plan = PgTrigger::Plan.new
    trigger = PgTrigger::Trigger.new.on("comments").before(:update).of(:title) do
      "UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id"
    end

    plan.drop_trigger(trigger)
    migration = PgTrigger::Generator::Migration.new(plan)
    output = migration.generate_output


    assert_match %r{\d+_drop_triggers_on_comments.rb}, migration.name
    assert_output_matches_file "drop_triggers_on_comments.rb", output
  end

  def test_generate_multiple_triggers
    plan = PgTrigger::Plan.new
    trigger = PgTrigger::Trigger.new.on("comments").before(:update).of(:title) do
      "UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id"
    end

    plan.update_trigger(trigger)
    migration = PgTrigger::Generator::Migration.new(plan)
    output = migration.generate_output

    assert_match %r{\d+_update_triggers_on_comments.rb}, migration.name
    assert_output_matches_file "update_triggers_on_comments.rb", output
  end

  private

  def assert_output_matches_file(filename, output)
    expected = File.binread(File.join(EXPECTATIONS_PATH, filename))
    assert_equal expected.sub!(%r{7\.0}, ActiveRecord::Migration.current_version.to_s), output
  end
end
