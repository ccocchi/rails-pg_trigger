# frozen_string_literal: true

require_relative "pg_trigger/version"
require_relative "pg_trigger/model"
require_relative "pg_trigger/trigger"
require_relative "pg_trigger/plan"
require_relative "pg_trigger/indented_string"

module PgTrigger
  class GenerationError < StandardError; end
  # Your code goes here...
end
