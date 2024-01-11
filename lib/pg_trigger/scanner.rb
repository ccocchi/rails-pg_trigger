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
      @definitions.filter_map do |defn|
        trigger = Trigger.from_definition(defn)
        next nil unless trigger
        next nil unless trigger.name.end_with?("_tr")

        if (fn = @functions[trigger.name])
          trigger.set_content_from_function(fn)
        end

        trigger
      end
    end

    private

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

        content = scanner.scan_until(/^\s*\$\$;/)
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
end
