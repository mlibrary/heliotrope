# frozen_string_literal: true

class Lessee < ApplicationRecord
  has_many :lessees_products
  has_many :products, through: :lessees_products

  validates :identifier, presence: true, allow_blank: false

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def components
    return [] if products.blank?
    Component.where(id: ComponentsProduct.where(product_id: products.map(&:id)).map(&:component_id)).distinct
  end
end
