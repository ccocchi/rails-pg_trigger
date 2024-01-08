# frozen_string_literal: true

require "test_helper"

class TestScanner < Minitest::Test
  @@string = begin
    path = File.join(File.expand_path(__dir__), "fixtures", "structure.sql")
    File.binread(path)
  end

  def setup
    @scanner = PgTrigger::Scanner.new(@@string)
  end

  def test_existing_triggers
    triggers = @scanner.triggers

    assert_instance_of Array, triggers
    assert_equal 2, triggers.size

    t = triggers.first

    assert_equal "comments_after_insert_tr", t[0]
    expected_content = "UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.comment_id;"
    assert_equal expected_content, t[1].split("\n").first
  end
end
