namespace :db do
  namespace :triggers do
    desc "Creates a new database migration representing changes in model-defined triggers"
    task migration: :environment do
      if ActiveRecord::Base.connection.migration_context.needs_migration?
        puts "Abort: some migrations are pending"
        exit(1)
      end

      require "pg_trigger/generator"

      Rails.application.eager_load!
      filename = PgTrigger::Generator.run(models: ActiveRecord::Base.descendants)

      if filename
        puts "Generated #{filename}"
      else
        puts "Everything up-to-date"
      end
    end
  end
end
