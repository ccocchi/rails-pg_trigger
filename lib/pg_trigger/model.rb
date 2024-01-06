# frozen_string_literal: true

module PgTrigger::Model
  module ClassMethods
    def _triggers = @_triggers

    def trigger
      tr = Trigger.new
      tr.on(table_name)

      @_triggers << tr
      tr
    end
  end
end
