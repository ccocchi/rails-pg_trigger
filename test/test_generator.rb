# frozen_string_literal: true

require "test_helper"

class TestGenerator < Minitest::Test
  def test_models
    assert_equal 2, PgTrigger::Generator.send(:models).size
  end

  def test_existing_triggers
    triggers = PgTrigger::Generator.send(:existing_triggers)

    assert triggers.is_a?(Array)
    assert_equal 2, triggers.size

    t = triggers.first

    assert_equal "comments_after_insert_tr", t[0]
    expected_content = "UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.comment_id;"
    assert_equal expected_content, t[1].split("\n").first
  end
end
