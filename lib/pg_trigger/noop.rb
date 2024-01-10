module PgTrigger::Noop
  def self.included(other)
    other.extend ClassMethods
  end

  module ClassMethods
    def trigger
    end
  end
end
