require_relative "indented_string"
require_relative "plan"
require_relative "scanner"

module PgTrigger
  module Generator
    class << self
      def run(models:)
        triggers = models.filter_map { |m| m._triggers.presence }.flatten
        scanner = Scanner.new(File.read(PgTrigger.structure_file_path))
        existing = scanner.triggers

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

        number = ActiveRecord::Migration.next_migration_number(0)
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
        migration_name = @plan.name.camelize

        @output << "# This migration was auto-generated via `rake db:triggers:migration'.\n\n"
        @output << "class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]\n"
      end

      def up_and_down
        up = IndentedString.new("def up\n", size: 2).indent.append_newline("execute <<-SQL").indent
        down = IndentedString.new("def down\n", size: 2).indent.append_newline("execute <<-SQL").indent

        @plan.new_triggers.each do |trigger|
          if trigger.create_function?
            up.append_raw_string trigger.create_function_sql
            down.append_raw_string trigger.drop_function_sql
          end

          up.append_raw_string trigger.create_trigger_sql
          down.append_raw_string trigger.drop_trigger_sql
        end

        @plan.removed_triggers.each do |trigger|
          if trigger.create_function?
            down.append_raw_string trigger.create_function_sql
            up.append_raw_string trigger.drop_function_sql
          end

          down.append_raw_string trigger.create_trigger_sql
          up.append_raw_string trigger.drop_trigger_sql
        end

        up.outdent.append_newline("SQL").outdent.append_newline("end")
        down.outdent.append_newline("SQL").outdent.append_newline("end")

        @output << [up, down].join("\n")
      end

      def footer
        @output << "end\n"
      end
    end
  end
end
