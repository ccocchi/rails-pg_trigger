# frozen_string_literal: true

class PgTrigger::IndentedString
  def initialize(str, size:)
    @spaces = " " * size
    @inner = @spaces + str
  end

  def empty
    @inner = +""
    self
  end

  def indent
    @spaces << "  "
    self
  end

  def outdent
    @spaces.slice!(-2, 2)
    self
  end

  def append(str)
    @inner << @spaces << str
    self
  end

  def append_raw_string(str, newline: true)
    str.each_line do |l|
      @inner << @spaces << l
    end
    endline if newline
    self
  end

  def append_newline(str)
    @inner << @spaces << str
    endline
  end
  alias_method :<<, :append_newline

  def endline
    @inner << "\n"
    self
  end

  def to_s = @inner

  alias_method :to_str, :to_s
end
