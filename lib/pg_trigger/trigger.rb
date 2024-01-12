# frozen_string_literal: true

require "active_support/core_ext/string/strip"
require_relative "indented_string"

module PgTrigger
  class Trigger
    class << self
      def chain(*methods)
        methods.each do |method|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            alias orig_#{method} #{method}

            def #{method}(*args, &block)
              orig_#{method}(*args)
              @content = normalize_string(yield) if block
              self
            end
          RUBY
        end
      end

      DEFN_REGEXP = [
        "\\ACREATE TRIGGER",
        "(?<name>\\w+)",
        "(?<timing>AFTER|BEFORE)",
        "(?<events>(?:INSERT|UPDATE|DELETE)(?: OR (?:INSERT|UPDATE|DELETE))?)",
        "(?:OF(?<columns>(?:\\s[a-z0-9_]+,?)+)\\s)?ON (?:[\\w\"]+\\.)?(?<table>\\w+)",
        "FOR EACH ROW(?: WHEN \\((?<where>[^\\)]+)\\))?",
        "EXECUTE FUNCTION (?:\\w+\\.)?(?<fn>\\w+)",
      ].join("\\s")
      .yield_self { |str| Regexp.new(str) }

      def from_definition(defn)
        match = defn.match(DEFN_REGEXP)

        if !match
          raise InvalidTriggerDefinition, defn if PgTrigger.raise_on_invalid_definition
          return
        end

        trigger = new
        trigger.named(match[:name]).on(match[:table])
        trigger.public_send(match[:timing].downcase, *match[:events].split(" OR ").map! { |e| e.downcase.to_sym })

        if (cols = match[:columns])
          trigger.of(*cols.split(", ").map!(&:lstrip))
        end

        if (where = match[:where])
          trigger.where(where)
        end

        trigger.nowrap if match[:fn] != match[:name]
        trigger
      end
    end

    attr_reader :table, :timing, :content, :columns, :events

    def initialize
      @name     = nil
      @table    = nil
      @timing   = nil
      @events   = []
      @columns  = []
      @content  = nil
      @where    = nil
      @options  = {}
    end

    def on(table_name)
      @table = table_name
    end

    def after(*events)
      @timing = :after
      @events.concat(format_events(events))
    end

    def before(*events)
      @timing = :before
      @events.concat(format_events(events))
    end

    def of(*columns)
      @columns.concat(columns)
    end

    def where(condition)
      @where = condition
    end

    def named(name)
      @name = name
    end

    def nowrap
      @options[:nowrap] = true
    end

    chain :on, :of, :after, :before, :named, :where, :nowrap

    def name
      @name ||= inferred_name
    end

    def where_clause = @where

    # Compare content without taking indentation into account
    def same_content_as?(other)
      content.gsub(/\s+/, " ") == other.content.gsub(/\s+/, " ")
    end

    FN_CONTENT_REGEX = /BEGIN\s+(?<content>.+;)\n\s+RETURN NULL;/m

    def set_content_from_function(str)
      if (match = str.match(FN_CONTENT_REGEX))
        @content = match[:content]
      end
    end

    def create_function?
      !@options[:nowrap]
    end

    def create_function_sql
      str = IndentedString.new(size: 4)
      str += @content

      <<~SQL
        CREATE OR REPLACE FUNCTION #{name}() RETURNS TRIGGER
        AS $$
          BEGIN
        #{str}
            RETURN NULL;
          END
        $$ LANGUAGE plpgsql;
      SQL
    end

    def create_trigger_sql
      whr = @where.nil? ? "" : "\nWHEN (#@where)"

      <<~SQL
        CREATE TRIGGER #{name}
        #{@timing.upcase} #{events.map(&:upcase).join(" OR ")} ON #{adapter.quote_table_name(@table)}
        FOR EACH ROW#{whr}
        EXECUTE FUNCTION #{name}();
      SQL
    end

    def drop_function_sql
      "DROP FUNCTION IF EXISTS #{name};"
    end

    def drop_trigger_sql
      "DROP TRIGGER IF EXISTS #{name} ON #{adapter.quote_table_name(@table)};"
    end

    private

    def format_events(ary)
      ary.map do |e|
        case e
        when :insert, :update, :delete then e
        when :create then :insert
        when :destroy then :delete
        else
          raise ArgumentError, "unknown #{e}, event should be :insert, :update or :delete"
        end
      end
    end

    def normalize_string(str)
      str = str.strip_heredoc
      str.rstrip!
      str.end_with?(";") ? str : "#{str};"
    end

    def adapter
      @adapter ||= ::ActiveRecord::Base.connection
    end

    def inferred_name
      [@table,
      @timing,
      @events.join("_or_"),
      ].join("_").downcase.slice(0, 60) << "_tr"
    end
  end
end
