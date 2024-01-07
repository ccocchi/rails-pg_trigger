# frozen_string_literal: true

require "test_helper"

class TestIndentedString < Minitest::Test
  def test_new_string
    str = PgTrigger::IndentedString.new("hello", size: 3)
    assert_equal "   hello", str.to_s
  end

  def test_append
    str = PgTrigger::IndentedString.new("hello", size: 2)
    str << "world"

    assert_equal "  hello  world", str.to_s
  end

  def test_indent
    str = PgTrigger::IndentedString.new("def foo", size: 0)
    str.indent
    str << "bar"

    assert_equal "def foo\n  bar", str.to_s
  end

  def test_outdent
    str = PgTrigger::IndentedString.new("bar", size: 2)
    str.outdent
    str << "end"

    assert_equal "  bar\nend", str.to_s
  end
end
