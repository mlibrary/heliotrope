# frozen_string_literal: true

class Lessee < ApplicationRecord
  has_many :lessees_products
  has_many :products, through: :lessees_products
  has_many :groupings_lessees
  has_many :groupings, through: :groupings_lessees

  validates :identifier, presence: true, allow_blank: false

  before_destroy do
    if products.present?
      errors.add(:base, "lessee has #{products.count} associated products!")
      throw(:abort)
    end

    if groupings.present?
      errors.add(:base, "lessee has #{groupings.count} associated groupings!")
      throw(:abort)
    end
  end

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def components
    return [] if products.blank?
    Component.where(id: ComponentsProduct.where(product_id: products.map(&:id)).map(&:component_id)).distinct
  end

  def grouping?
    grouping.present?
  end

  def grouping
    Grouping.find_by(identifier: identifier)
  end

  def not_groupings
    Grouping.where.not(id: groupings.map(&:id))
  end

  def institution?
    institution.present?
  end

  def institution
    Institution.find_by(identifier: identifier)
  end
end
