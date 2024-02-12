module PgTrigger::Noop
  def self.included(other)
    other.extend ClassMethods
  end

  class Proxy
    def self.chain(*methods)
      methods.each do |m|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{m}(*)
            self
          end
        RUBY
      end
    end

    chain :on, :of, :after, :before, :named, :where, :nowrap
  end

  module ClassMethods
    def trigger
      Proxy.new
    end
  end
end
