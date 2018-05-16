# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :components_products
  has_many :components, through: :components_products
  has_many :lessees_products
  has_many :lessees, through: :lessees_products

  validates :identifier, presence: true, allow_blank: false, uniqueness: true
  # validates :purchase, presence: true, allow_blank: false

  before_destroy do
    if components.present?
      errors.add(:base, "product has #{components.count} associated components!")
      throw(:abort)
    end
    if lessees.present?
      errors.add(:base, "product has #{lessees.count} associated lessees!")
      throw(:abort)
    end
  end

  def update?
    true
  end

  def destroy?
    !(components.present? || lessees.present?)
  end

  def not_components
    Component.where.not(id: components.map(&:id))
  end

  def not_lessees
    Lessee.where.not(id: lessees.map(&:id))
  end
end
