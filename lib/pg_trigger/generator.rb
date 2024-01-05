require_relative "plan"

module PgTrigger
  class Generator
    def run
      generate_migration(build_plan)
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
      source = generate_source(plan)

      filename = "#{number}_#{name}.rb"
      File.binwrite(filename, source)

      filename
    end

    def infer_name_from(plan)
      action = case plan.action
        when :create then "create"
        when :drop then "drop"
        when :update then "update"
        else
          "change"
        end
      end

      table = plan.table == :multi ? "multiple_tables" else plan.table

      "#{action}_triggers_on_#{table}"
    end

    def generate_source(plan)
    #       File.open(filename, "w") { |f| f.write <<-RUBY }
# # This migration was auto-generated via `rake db:triggers:migration'.

# class #{migration_name} < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
#   def up
#     #{(up_drop_triggers + up_create_triggers).map{ |t| t.to_ruby('    ') }.join("\n\n").lstrip}
#   end

#   def down
#     #{(down_drop_triggers + down_create_triggers).map{ |t| t.to_ruby('    ') }.join("\n\n").lstrip}
#   end
# end
#       RUBY
#       filename
    end

    def existing_triggers
      content = File.binread("db/structure.sql")
      scanner = StringScanner.new(content)
      existing = []

      while true
        break unless scanner.skip_until /^CREATE FUNCTION /
        name = scanner.scan(/[\w\.]+_tr/)
        next unless name

        scanner.skip_until /^BEGIN/
        content = scanner.scan_until /^END/
        existing << [name, content.strip]
      end

      existing
    end

    def models
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
    end
  end
end
