# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "yaml"
require "active_record"
require "pg_trigger"
require "pg_trigger/generator"

require "minitest/autorun"

dir = File.expand_path(__dir__)

config = YAML.safe_load(File.read(File.join(dir, "database.yml")))
ActiveRecord::Base.establish_connection(config)

MIGRATIONS_DIR = File.join(Dir.tmpdir, "migrate")

FileUtils.mkdir_p MIGRATIONS_DIR
PgTrigger.structure_file_path = File.join(dir, "fixtures", "structure.sql")
PgTrigger.migrations_path = MIGRATIONS_DIR

ActiveRecord::Base.include(PgTrigger::Model)

Dir.glob(File.join(dir, "models/*.rb")) { |file| require file }

PgTrigger::Plan.attr_reader :actions

Comment.attr_writer :_triggers
