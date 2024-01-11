# frozen_string_literal: true

require "test_helper"

class TestIndentedString < Minitest::Test
  def setup
    @str = PgTrigger::IndentedString.new(size: 2)
  end

  def test_new_string
    assert_equal "", @str.to_s
  end

  def test_append
    @str << "def indented"
    assert_equal "  def indented", @str.to_s
  end

  def test_plus
    multiline = <<~SQL
      hello
      world
    SQL

    @str += multiline

    assert_equal "  hello\n  world\n", @str.to_s
  end

  def test_indent
    @str << "def foo\n"
    @str.indent!
    @str << "bar"

    assert_equal "  def foo\n    bar", @str.to_s
  end

  def test_outdent
    @str << "bar\n"
    @str.outdent!
    @str << "end"

    assert_equal "  bar\nend", @str.to_s
  end

  def test_newline
    @str.newline
    assert_equal "\n", @str.to_s
  end
end
