# frozen_string_literal: true

require_relative "pg_trigger/version"
require_relative "pg_trigger/model"
require_relative "pg_trigger/trigger"
require_relative "pg_trigger/generator"

module PgTrigger
  class GenerationError < StandardError; end

  class << self
    attr_accessor :structure_file_path, :schema
  end

  self.structure_file_path = "db/structure.sql"
  self.schema = "public"
end
