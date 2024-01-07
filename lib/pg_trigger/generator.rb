require_relative "plan"
require_relative "indented_string"

module PgTrigger
  module Generator
    class << self
      def run
        plan = build_plan
        raise "TODO: empty plan" if plan.empty?

        generate_migration(plan)
      end

      private

      def build_plan
        triggers = models.filter_map { |m| m._triggers.presence }.flatten
        existing = existing_triggers.to_h

        plan = Plan.new

        # Find new or updated triggers
        triggers.each do |t|
          existing_content = existing[t.name]
          if existing_content
            plan.update_trigger(t) if t.content != content
          else
            plan.add_trigger(t)
          end
        end

        # Find removed triggers
        existing.each_key do |name|
          next if triggers.any? { |t| t.name == name }
          plan.drop_trigger_by_name(name)
        end

        plan
      end

      def generate_migration(plan)
        number = ActiveRecord::Generators::Migration.next_migration_number("db/migrate")
        name = infer_name_from(plan)
        source = generate_source(plan, name)

        filename = "#{number}_#{name}.rb"
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

      def existing_triggers
        content = File.binread(PgTrigger.structure_file_path)
        scanner = StringScanner.new(content)
        existing = []

        while true
          break unless scanner.skip_until(/^CREATE FUNCTION /)
          name = scanner.scan(/[\w\.]+_tr/)
          next unless name

          scanner.skip_until(/^BEGIN/)
          content = scanner.scan_until(/^END/)

          name.delete_prefix!("#{PgTrigger.schema}.")
          existing << [name, content.strip]
        end

        existing
      end

      def models
        Rails.application.eager_load! if defined?(Rails)
        ActiveRecord::Base.descendants
      end
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
