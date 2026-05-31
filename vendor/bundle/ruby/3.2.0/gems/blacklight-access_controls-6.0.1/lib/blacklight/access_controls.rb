# frozen_string_literal: true

module Blacklight
  module AccessControls
    extend ActiveSupport::Autoload

    autoload :Config
    autoload :User
    autoload :PermissionsQuery
    autoload :PermissionsCache
    autoload :Ability
    autoload :Enforcement
    autoload :SearchBuilder
    autoload :Catalog
  end
end
