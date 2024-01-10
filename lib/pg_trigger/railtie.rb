require "rails/railtie"

module PgTrigger
  class Railtie < Rails::Railtie
    initializer "pg_trigger.model" do
      mod = if Rails.env.development? || Rails.env.test?
        require "pg_trigger/model"
        PgTrigger::Model
      else
        require "pg_trigger/noop"
        PgTrigger::Noop
      end

      ActiveSupport.on_load :active_record do
        self.include mod
      end
    end

    rake_tasks do
      load "tasks/pg_trigger.rake"
    end
  end
end
