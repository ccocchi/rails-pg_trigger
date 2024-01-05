module PgTrigger
  class Plan
    attr_reader :action, :table

    def initialize
      @action = nil
      @table  = nil
      @inner  = Hash.new { |h, k| h[k] = [] }.tap(&:compare_by_identity)
    end

    def empty? = @inner.empty?

    def add_trigger(t)
      set_action :create
      set_table t.table

      @inner[:added] << t
    end

    def drop_trigger_by_name(name)
      set_action :drop

      @inner[:removed] << name
    end

    def update_trigger(t)
      set_action :update
      set_table t.table

      @inner[:updated] << t
    end

    private

    def set_action(type)
      if @action
        @action = :multi
      else
        @action = :type
      end
    end

    def set_table(name)
      if @table
        @table = "multiple"
      else
        @table = name
      end
    end
  end
end
