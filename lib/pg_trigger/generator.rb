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
        up(:up)
        @output << "\n"
        up(:down)
        footer
      end

      private

      def header
        migration_name = @plan.name.camelize

        @output << "# This migration was auto-generated via `rake db:triggers:migration'.\n\n"
        @output << "class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]\n"
      end

      def up(dir)
        res = IndentedString.new(size: 2, initial_indent: true)
        res << "def #{dir}\n"
        res.indent!

        create = ->(t) do
          execute_block do |s|
            if t.create_function?
              s += t.create_function_sql
              s.newline
            end
            s += t.create_trigger_sql
          end
        end

        drop = ->(t) do
          execute_block do |s|
            s += t.drop_trigger_sql
            s.newline
            if t.create_function?
              s += t.drop_function_sql
            end
          end
        end

        blocks = @plan.new_triggers.map { |t| (dir == :up ? create : drop).call(t) }
        blocks.concat @plan.removed_triggers.map { |t| (dir == :up ? drop : create).call(t) }

        res += blocks.join("\n")
        res.outdent!
        res << "end\n"
        @output << res.to_s
      end

      def footer
        @output << "end\n"
      end

      def execute_block
        res = IndentedString.new(size: 0)
        res << "execute <<~SQL\n"
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
