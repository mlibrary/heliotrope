# frozen_string_literal: true

class Component < ApplicationRecord
  has_many :components_products
  has_many :products, through: :components_products

  validates :handle, presence: true, allow_blank: false, uniqueness: true

  before_destroy do
    if products.present?
      errors.add(:base, "component has #{products.count} associated products!")
      throw(:abort)
    end
  end

  def update?
    true
  end

  def destroy?
    products.blank?
  end

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def lessees(recursive = false)
    return [] if products.blank?
    records = Lessee.where(id: LesseesProduct.where(product_id: products.map(&:id)).map(&:lessee_id)).distinct
    return records unless recursive
    rvalue = []
    records.each { |r| rvalue << r }
    grouping_lessees = rvalue.select(&:grouping?)
    grouping_lessees.each { |l| rvalue << l.grouping.lessees }
    rvalue.flatten
  end
end
