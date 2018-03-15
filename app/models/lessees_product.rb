# frozen_string_literal: true

class LesseesProduct < ApplicationRecord
  belongs_to :lessee
  belongs_to :product
end
