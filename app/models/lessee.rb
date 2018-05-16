# frozen_string_literal: true

class Lessee < ApplicationRecord
  has_many :lessees_products
  has_many :products, through: :lessees_products
  has_many :groupings_lessees
  has_many :groupings, through: :groupings_lessees

  validates :identifier, presence: true, allow_blank: false, uniqueness: true

  before_validation(on: :update) do
    if identifier_changed?
      if Institution.find_by(identifier: identifier_was).present?
        errors.add(:identifier, "institution lessee identifier can not be changed!")
        throw(:abort)
      end
      if Grouping.find_by(identifier: identifier_was).present?
        errors.add(:identifier, "grouping lessee identifier can not be changed!")
        throw(:abort)
      end
    end
  end

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

  def update?
    !(institution? || grouping?)
  end

  def destroy?
    !(institution? || grouping? || products.present? || groupings.present?)
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
