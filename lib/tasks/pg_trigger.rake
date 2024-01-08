namespace :db do
  namespace :triggers
    describe "Creates a new database migration representing changes in model-defined triggers"
    task generate_migration: :environment do
      require "pg_trigger/generator"

      Rails.application.eager_load!
      filename = PgTrigger::Generator.run(ActiveRecord::Base.descendants)

      if filename
        puts "Generated #{filename}"
      else
        puts "Everything up-to-date"
      end
    end
  end
end
