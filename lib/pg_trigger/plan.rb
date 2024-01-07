module PgTrigger
  class Plan
    attr_reader :type, :table

    def initialize
      @type = nil
      @table = nil
      @actions = Hash.new { |h, k| h[k] = [] }.tap(&:compare_by_identity)
    end

    def empty? = @actions.empty?

    def add_trigger(t)
      set_type :create
      set_table t.table

      @actions[:to_add] << t
    end

    def drop_trigger_by_name(name)
      set_type :drop

      @actions[:to_remove] << name
    end

    def update_trigger(t)
      set_type :update
      set_table t.table

      @actions[:to_remove] << t.name
      @actions[:to_add] << t
    end

    private

    def set_type(type)
      if @type
        @type = :multi if @type != type
      else
        @type = type
      end
    end

    def set_table(name)
      if @table
        @table = "multiple" if @table != name
      else
        @table = name
      end
    end
  end
end
