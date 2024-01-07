# frozen_string_literal: true

class PgTrigger::Trigger
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

  def create_function?
    !@options[:nowrap]
  end

  def create_function_sql
    <<~SQL
      CREATE OR REPLACE FUNCTION #{name}() RETURNS TRIGGER
      AS $$
        BEGIN
          #{@content};
          RETURN NULL;
        END
      $$ LANGUAGE plpgsql;
    SQL
  end

  def create_trigger_sql
    whr = @where.nil? ? "" : "\nWHEN (#@where)\n"

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
        raise ArgumentError, "trigger event should be :insert, :update or :delete"
      end
    end
  end

  def adapter
    @adapter ||= ActiveRecord::Base.connection
  end

  def inferred_name
    [@table,
     @timing,
     @events.join("_or_"),
    ].join("_").downcase.slice(0, 60) << "_tr"
  end
end
