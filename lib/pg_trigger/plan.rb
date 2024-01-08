module PgTrigger
  # This class represents the actions needed to go from the existing triggers to
  # the expected triggers defined in the models.
  #
  class Plan
    class Builder
      def initialize(expected, existing)
        @expected = expected
        @existing = existing
      end

      def result
        plan = Plan.new

        # Find new or updated triggers
        @expected.each do |t|
          existing_content = @existing[t.name]
          if existing_content
            plan.update_trigger(t) if t.content != existing_content
          else
            plan.add_trigger(t)
          end
        end

        # Find removed triggers
        @existing.each_key do |name|
          next if @expected.any? { |t| t.name == name }
          plan.drop_trigger_by_name(name)
        end

        plan
      end
    end

    attr_reader :type, :table

    def initialize
      @name = nil
      @type = nil
      @table = nil
      @actions = Hash.new { |h, k| h[k] = [] }.tap(&:compare_by_identity)
    end

    def new_triggers = @actions[:to_add]

    def removed_triggers = @actions[:to_remove]

    def empty? = @actions.empty?

    def name
      @name ||= begin
        action = case type
        when :create then "create"
        when :drop then "drop"
        when :update then "update"
        else
          "change"
        end

        table_name = table == :multi ? "multiple_tables" : table

        "#{action}_triggers_on_#{table}"
      end
    end

    def add_trigger(t)
      set_type :create
      set_table t.table

      @actions[:to_add] << t
    end

    def drop_trigger_by_name(name)
      set_type :drop
      if (data = name.match(/\A(\w+)_(before|after)_/))
        set_table data[1]
      end

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
