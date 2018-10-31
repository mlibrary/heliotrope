# frozen_string_literal: true

class Component < ApplicationRecord
  include Filterable

  scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :handle_like, ->(like) { where("handle like ?", "%#{like}%") }

  has_many :components_products
  has_many :products, through: :components_products

  # TODO: Uncomment validators and remove validates handle
  # validates :identifier, presence: true, allow_blank: false, uniqueness: true
  # validates :noid, presence: true, allow_blank: false
  validates :handle, presence: true, allow_blank: false, uniqueness: true

  before_destroy do
    if products.present?
      errors.add(:base, "component has #{products.count} associated products!")
      throw(:abort)
    end
    if policies.present?
      errors.add(:base, "component has #{policies.count} associated policies!")
      throw(:abort)
    end
  end

  def update?
    true
  end

  def destroy?
    products.blank? && policies.blank?
  end

  def not_products
    Product.where.not(id: products.map(&:id))
  end

  def lessees
    return [] if products.blank?
    Lessee.where(id: LesseesProduct.where(product_id: products.map(&:id)).map(&:lessee_id)).distinct
  end

  def noid
    return @noid if @noid.present?
    @noid = super
    @noid ||= HandleService.noid(handle)
  end

  def monograph?
    NoidService.from_noid(noid).type == :monograph
  end

  def file_set?
    NoidService.from_noid(noid).type == :file_set
  end

  def policies
    Policy.resource_policies(self)
  end
end
