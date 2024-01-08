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

        migration = Migration.new(plan)
        migration.save_to_file
        migration.name
      end
    end

    class Migration
      attr_reader :name

      def initialize(plan)
        @plan = plan
        @output = nil

        number = ActiveRecord::Generators::Migration.next_migration_number(PgTrigger.migrations_path)
        @name = "#{number}_#{plan.name}.rb"
      end

      def save_to_file
        generate_output if @output.nil?

        filename = name
        File.binwrite(File.join(PgTrigger.migrations_path, filename), @output)

        filename
      end

      def generate_output
        @output = ""
        header
        up_and_down
        footer
      end

      private

      def header
        migration_name = plan.name.camelize

        @output << "# This migration was auto-generated via `rake db:triggers:migration'.\n\n"
        @output << "class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]\n"
      end

      def up_and_down
        up = IndentedString.new("def up\n", size: 2).indent.append_newline("execute <<-SQL")
        down = IndentedString.new("def down\n", size: 2).indent.append_newline("execute <<-SQL")

        @plan.new_triggers.each do |trigger|
          if trigger.create_function?
            up << trigger.create_function_sql
            down << trigger.drop_function_sql
          end

          up << trigger.create_trigger_sql
          down << trigger.drop_trigger_sql
        end

        up.outdent
        down.outdent
        up << "SQL"
        down << "SQL"

        @output << [up, down].join("\n")
      end

      def footer
        @output << "end\n"
      end
    end
  end
end
