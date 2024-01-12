module ActiveRecord
  module TriggerHelpers
    def create_trigger(name, content)
      say_with_time("create_trigger(#{name})") do
        connection.execute(content)
      end
    end

    def drop_trigger(name, content)
      say_with_time("drop_trigger(#{name})") do
        connection.execute(content)
      end
    end
  end
end
