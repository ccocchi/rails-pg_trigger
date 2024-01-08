# frozen_string_literal: true

require "test_helper"

class TestGenerator < Minitest::Test
  EXPECTATIONS_PATH = File.join(File.expand_path(__dir__), "expectations")

  def test_generate_new_trigger
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

  private

  def assert_output_matches_file(filename, output)
    expected = File.binread(File.join(EXPECTATIONS_PATH, filename))
    assert_equal expected, output
  end
end
