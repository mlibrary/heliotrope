# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :components_products
  has_many :components, through: :components_products
  has_many :lessees_products
  has_many :lessees, through: :lessees_products

  validates :identifier, presence: true, allow_blank: false
  validates :purchase, presence: true, allow_blank: false

  def not_components
    Component.where.not(id: components.map(&:id))
  end

  def not_lessees
    Lessee.where.not(id: lessees.map(&:id))
  end
end
