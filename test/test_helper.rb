# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "yaml"
require "active_record"
require "pg_trigger"

require "minitest/autorun"

config = YAML.safe_load(File.read(File.join(File.expand_path(__dir__), "database.yml")))
ActiveRecord::Base.establish_connection(config)
