# frozen_string_literal: true

class PgTrigger::IndentedString
  def initialize(str, size:)
    @spaces = " " * size
    @inner = @spaces + str
  end

  def indent
    @spaces << "  "
    endline
  end

  def outdent
    @spaces.slice!(-2, 2)
    endline
  end

  def <<(str)
    @inner << @spaces << str
  end

  def endline
    @inner << "\n"
  end

  def to_s = @inner

  alias_method :to_str, :to_s
end
