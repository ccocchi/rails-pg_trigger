require_relative "indented_string"
require_relative "model"
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
        add_direction(:up)
        @output << "\n"
        add_direction(:down)
        footer
      end

      private

      def header
        migration_name = @plan.name.camelize

        @output << "# This migration was auto-generated via `rake db:triggers:migration'.\n\n"
        @output << "class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]\n"
      end

      def add_direction(dir)
        res = IndentedString.new(size: 2, initial_indent: true)
        res << "def #{dir}\n"
        res.indent!

        blocks = []

        if dir == :up
          blocks.concat @plan.removed_triggers.map { |t| drop_trigger_command(t) }
          blocks.concat @plan.new_triggers.map { |t| create_trigger_command(t) }
        else
          blocks.concat @plan.new_triggers.map { |t| drop_trigger_command(t) }
          blocks.concat @plan.removed_triggers.map { |t| create_trigger_command(t) }
        end

        res += blocks.join("\n")
        res.outdent!
        res << "end\n"
        @output << res.to_s
      end

      def footer
        @output << "end\n"
      end

      def create_trigger_command(t)
        make_command("create_trigger", t) do |s|
          if t.create_function?
            s += t.create_function_sql
            s.newline
          end
          s += t.create_trigger_sql
        end
      end

      def drop_trigger_command(t)
        make_command("drop_trigger", t) do |s|
          s += t.drop_trigger_sql
          if t.create_function?
            s.newline
            s += t.drop_function_sql
          end
        end
      end

      def make_command(cmd, t)
        res = IndentedString.new(size: 0)
        res << %{#{cmd} "#{t.name}", <<~SQL\n}
        res.indent!
        yield res
        res.outdent!
        res.newline
        res << "SQL\n"
        res.to_s
      end
    end
  end
end
