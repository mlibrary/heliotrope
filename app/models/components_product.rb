# frozen_string_literal: true

class ComponentsProduct < ApplicationRecord
  belongs_to :component
  belongs_to :product
end
