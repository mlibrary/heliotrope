# frozen_string_literal: true

class ProductNoid < ApplicationRecord
  validates :product, presence: true, allow_blank: false
  validates :noid, presence: true, allow_blank: false
  validates :product, uniqueness: { scope: :noid }
end
