# frozen_string_literal: true

class Lessee < ApplicationRecord
  include Filterable

  scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }

  has_many :lessees_products
  has_many :products, through: :lessees_products

  validates :identifier, presence: true, allow_blank: false, uniqueness: true

  before_validation(on: :update) do
    if identifier_changed?
      if Institution.find_by(identifier: identifier_was).present?
        errors.add(:identifier, "institution lessee identifier can not be changed!")
        throw(:abort)
      end
    end
  end

  before_destroy do
    if products.present?
      errors.add(:base, "lessee has #{products.count} associated products!")
      throw(:abort)
    end
  end

  def update?
    !institution?
  end

  def destroy?
    !(institution? || products.present?)
  end

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def components
    return [] if products.blank?
    Component.where(id: ComponentsProduct.where(product_id: products.map(&:id)).map(&:component_id)).distinct
  end

  def institution?
    institution.present?
  end

  def institution
    Institution.find_by(identifier: identifier)
  end

  def policies
    Policy.agent_policies(self)
  end
end
