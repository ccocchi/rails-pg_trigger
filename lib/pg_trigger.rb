# frozen_string_literal: true

require_relative "pg_trigger/version"
require_relative "pg_trigger/railtie"

module PgTrigger
  class InvalidTriggerDefinition < StandardError; end

  class << self
    attr_accessor :structure_file_path, :schema, :migrations_path
  end

  self.structure_file_path = "db/structure.sql"
  self.schema = "public"
  self.migrations_path = "db/migrate"
end
