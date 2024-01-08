# frozen_string_literal: true

module PgTrigger::Model
  def self.included(other)
    other.extend ClassMethods
  end

  module ClassMethods
    attr_reader :_triggers

    def trigger
      tr = PgTrigger::Trigger.new
      tr.on(table_name)

      @_triggers ||= []
      @_triggers << tr
      tr
    end
  end
end
