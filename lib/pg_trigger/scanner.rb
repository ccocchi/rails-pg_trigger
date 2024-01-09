# frozen_string_literal: true

require "strscan"

module PgTrigger
  class Scanner
    def initialize(str)
      @str = str
      @functions = {}
      @definitions = []

      parse
    end

    def triggers
      @definitions.map do |defn|
        trigger = Trigger.from_definition(defn)

        if (fn = @functions[trigger.name])
          trigger.set_content_from_function(fn)
        end

        trigger
      end
    end

    def parse
      scanner = ::StringScanner.new(@str)
      pos = 0

      prefix = if (schema = PgTrigger.schema)
        "#{schema}."
      end

      while true
        break unless scanner.skip_until(/^CREATE FUNCTION /)
        name = scanner.scan(/[\w\.]+_tr/)
        next unless name

        content = scanner.scan_until(/^\$\$;/)
        pos = scanner.pos

        name.delete_prefix!(prefix) if prefix
        @functions[name] = content
      end

      scanner.pos = pos
      while true
        break unless scanner.skip_until(/^CREATE TRIGGER/)
        scanner.pos -= 14

        defn = scanner.scan_until(/;/)
        @definitions << defn
      end
    end
  end

  class Scanner2
    def initialize(io)
      @io = io
      @functions = {}
      @definitions = []

      parse
    end

    def triggers
      @definitions.map do |defn|
        trigger = Trigger.from_definition(defn)

        if (fn = @functions[trigger.name])
          trigger.set_content_from_function(fn)
        end

        trigger
      end
    end

    private

    def parse
      while (block = next_block)
        if (match = block.match(%r{\ACREATE FUNCTION (?:\w+.)?(\w+_tr)\(\)}))
          @functions[match[1]] = block
        elsif block.start_with?("CREATE TRIGGER")
          @definitions << block
        end
      end
    end

    def next_block
      block = +""

      while (line = @io.gets)
        if line == "\n"
          break if block.size > 0
          next # skip newlines at the start of a block
        end

        block << line unless line.start_with?('--')
      end

      block == "" ? nil : block
    end
  end
end
