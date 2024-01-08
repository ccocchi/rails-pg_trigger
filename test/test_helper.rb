# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "yaml"
require "active_record"
require "pg_trigger"

require "minitest/autorun"

dir = File.expand_path(__dir__)

config = YAML.safe_load(File.read(File.join(dir, "database.yml")))
ActiveRecord::Base.establish_connection(config)

PgTrigger.structure_file_path = File.join(dir, "fixtures", "structure.sql")

ActiveRecord::Base.include(PgTrigger::Model)

Dir.glob(File.join(dir, "models/*.rb")) { |file| require file }

PgTrigger::Plan.attr_reader :actions
