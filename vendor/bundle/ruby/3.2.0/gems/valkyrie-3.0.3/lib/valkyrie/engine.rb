# frozen_string_literal: true

require 'rails/engine'
##
# This engine exists for the sole purpose of enabling the
#   `valkyrie_engine:install:migrations` rake task from an including Rails
#   application. It technically enables a whole host of other functionality -
#   don't use it, please.
module Valkyrie
  class Engine < Rails::Engine
  end
end
