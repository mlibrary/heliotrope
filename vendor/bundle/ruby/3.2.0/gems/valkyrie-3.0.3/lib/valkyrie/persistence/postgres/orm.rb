# frozen_string_literal: true
require 'valkyrie/persistence/postgres/orm/resource'
module Valkyrie::Persistence::Postgres
  # Namespace for ActiveRecord access in Postgres adapter.
  module ORM
    # Provides the name prefix for the ActiveRecord database table name
    # (Maps to the data model for persistence)
    # @see https://api.rubyonrails.org/classes/ActiveRecord/ModelSchema.html#method-c-table_name_prefix
    # @return [String]
    def self.table_name_prefix
      'orm_'
    end
  end
end
