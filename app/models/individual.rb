# frozen_string_literal: true

class Individual < ApplicationRecord
  include Filterable

  scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :name_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :email_like, ->(like) { where("identifier like ?", "%#{like}%") }

  validates :identifier, presence: true, allow_blank: false, uniqueness: true
  validates :email, presence: true, allow_blank: false, uniqueness: true

  before_validation(on: :create) do
    if Lessee.find_by(identifier: identifier).present?
      errors.add(:identifier, "lessee identifier #{identifier} exists!")
      throw(:abort)
    end
  end

  before_validation(on: :update) do
    if identifier_changed?
      errors.add(:identifier, "institution identifier can not be changed!")
      throw(:abort)
    end
  end

  before_create do
    begin
      Lessee.create!(identifier: identifier)
    rescue StandardError
      errors.add(:identifier, "create lessee #{identifier} fail!")
      throw(:abort)
    end
  end

  before_destroy do
    if lessee.products.present?
      errors.add(:base, "institution has #{lessee.products.count} associated products!")
      throw(:abort)
    end
  end

  after_destroy do
    lessee.destroy!
  end

  def update?
    true
  end

  def destroy?
    !(lessee? && lessee.products.present?)
  end

  def lessee?
    lessee.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end

  def products
    return [] if policies.blank?
    Product.find(id: policies.map(&:resource_id))
  end

  def components
    components = []
    products.each do |product|
      components << product.components
    end
    components.flatten.uniq
  end

  def policies
    Policy.agent_policies(self)
  end
end
