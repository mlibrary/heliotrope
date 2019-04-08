# frozen_string_literal: true

module Greensub
  class ComponentsProduct < ApplicationRecord
    belongs_to :component
    belongs_to :product
  end
end
