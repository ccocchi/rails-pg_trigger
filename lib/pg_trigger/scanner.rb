# frozen_string_literal: true

module PgTrigger
  class Scanner
    def initialize(str)
      @str = str
    end

    def triggers
      scanner = StringScanner.new(@str)
      existing = []
      prefix = if (schema = PgTrigger.schema)
        "#{schema}."
      end

      while true
        break unless scanner.skip_until(/^CREATE FUNCTION /)
        name = scanner.scan(/[\w\.]+_tr/)
        next unless name

        scanner.skip_until(/^BEGIN\s/)
        content = scanner.scan_until(/^\s+RETURN NULL;/)

        name.delete_prefix!(prefix) if prefix
        existing << [name, content.strip]
      end

      existing
    end
  end
end
