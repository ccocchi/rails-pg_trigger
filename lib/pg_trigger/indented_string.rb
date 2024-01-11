# frozen_string_literal: true

class PgTrigger::IndentedString
  def initialize(size:, initial_indent: true)
    @spaces = " " * size
    @inner = +""
    @start = initial_indent
  end

  def indent!
    @spaces << "  "
  end

  def outdent!
    @spaces.slice!(-2, 2)
  end

  def append(str)
    @inner << @spaces << str
    self
  end
  alias_method :<<, :append

  def +(str)
    str.each_line do |l|
      if l == "\n"
        @inner << l
      else
        @inner << @spaces << l
      end
    end
    self
  end

  def newline
    @inner << "\n"
  end

  # def append_raw_string(str, newline: true)
  #   endline if newline
  #   self
  # end

  # def append_newline(str)
  #   @inner << @spaces << str
  #   endline
  # end
  # alias_method :<<, :append_newline

  # def endline
  #   @inner << "\n"
  #   self
  # end

  def to_s = @inner

  alias_method :to_str, :to_s
end
