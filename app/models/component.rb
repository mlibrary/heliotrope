# frozen_string_literal: true

class Component < ApplicationRecord
  has_many :components_products
  has_many :products, through: :components_products

  validates :handle, presence: true, allow_blank: false

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def lessees
    return [] if products.blank?
    Lessee.where(id: LesseesProduct.where(product_id: products.map(&:id)).map(&:lessee_id)).distinct
  end
end
