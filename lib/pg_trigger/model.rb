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
      @table    = nil
      @timing   = nil
      @events   = []
      @columns  = []
      @content  = nil
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

    chain :on, :of, :after, :before

    private

    # def adapter
    #   @adapter ||= ActiveRecord::Base.connection
    # end

    def inferred_name
      [@table,
       @timing,
       @event,
       "row"
      ].join("_").downcase.gsub(/[^a-z0-9_]/, '_').gsub(/_+/, '_')[0, 60] + "_tr"
    end
  end
end
