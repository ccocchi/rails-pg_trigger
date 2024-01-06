# frozen_string_literal: true

module PgTrigger::Model
  module ClassMethods
    def _triggers = @_triggers

    def trigger
      proxy = Proxy.new
      proxy.on(table_name)

      @_triggers << proxy
      proxy
    end
  end

  class Proxy
    def self.chain(*methods)
      methods.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          alias orig_#{method} #{method}

          def #{method}(*args, &block)
            orig_#{method}(*args)
            @content = yield if block
            self
          end
        RUBY
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
    end

    def on(table_name)
      @table = table_name
    end

    def after(*events)
      @timing = :after
      @events.concat(events)
    end

    def before(*events)
      @timing = :before
      @events.concat(events)
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

    chain :on, :of, :after, :before, :named, :where

    def name
      @name ||= inferred_name
    end

    def create_function_sql
      <<~SQL
        CREATE OR REPLACE FUNCTION #{name}() RETURNS TRIGGER
        AS $$
          BEGIN
            #{@content}
          END
        $$ LANGUAGE plpgsql;
      SQL
    end

    def create_trigger_sql
      whr = @where.nil? ? "" : "WHEN (#@where)"

      <<~SQL
        CREATE TRIGGER #{name}
        #{@timing.upcase} #{events.map(&:upcase).join(" OR ")} ON #{adapter.quote_table_name(@table)}
        FOR EACH ROW
        #{whr}
        EXECUTE FUNCTION #{name}();
      SQL
    end

    def drop_function_sql
      "DROP FUNCTION IF EXISTS #{name}"
    end

    def drop_trigger_sql
      "DROP TRIGGER IF EXISTS #{name} ON #{adapter.quote_table_name(@table)}"
    end

    private

    def adapter
      @adapter ||= ActiveRecord::Base.connection
    end

    def inferred_name
      [@table,
       @timing,
       @event.join("_or_"),
      ].join("_").downcase.slice(0, 60).append("_tr")
    end
  end
end
