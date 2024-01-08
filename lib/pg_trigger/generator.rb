require_relative "indented_string"
require_relative "plan"
require_relative "scanner"

module PgTrigger
  module Generator
    class << self
      def run(models)
        triggers = models.filter_map { |m| m._triggers.presence }.flatten
        scanner = Scanner.new(File.read(PgTrigger.structure_file_path))
        existing = scanner.triggers.to_h

        plan = Plan::Builder.new(triggers, existing).result
        return if plan.empty?

        generate_migration(plan)
      end

      private

      def generate_migration(plan)
        number = ActiveRecord::Generators::Migration.next_migration_number(PgTrigger.migrations_path)
        source = generate_source(plan)

        filename = "#{number}_#{plan.name}.rb"
        File.binwrite(filename, source)

        filename
      end

      def generate_source(plan, name)
        [
          header(name),
          up(plan),
          down(plan),
          footer
        ].join("\n")
      end

      # def models
      #   Rails.application.eager_load! if defined?(Rails)
      #   ActiveRecord::Base.descendants
      # end
    end
  end
end


#     def header(filename)
#       <<-STR.rstrip
# # This migration was auto-generated via `rake db:triggers:migration'.

# class #{migration_name.camelize} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
#       STR
#     end

#     def up(plan)
#       triggers = plan.triggers_to_create.map do |trigger|
#         str = IndentedString.new("execute <<-SQL", size: 4)
#         str.indent
#         if trigger.create_function?
#           str << trigger.create_function_sql
#           str.endline
#         end
#         str << trigger.create_trigger_sql
#         str.outdent
#         str << "SQL\n"
#         str.to_s
#       end

#       return if triggers.empty?
#       <<-STR
#   def up
#     #{triggers.join("\n\n")}
#   end
#       STR
#     end

#     def down
#       triggers = plan.triggers_to_drop.map do |trigger|
#         <<-STR
#     execute <<-SQL
#       #{trigger.drop_function_sql};
#       #{trigger.drop_trigger_sql};
#     SQL
#         STR
#       end

#       return if triggers.empty?
#       <<-STR
#   def down
#     #{triggers.join("\n\n")}
#   end
#       STR
#     end

#     def footer = "end"
