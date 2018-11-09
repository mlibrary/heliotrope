# frozen_string_literal: true

class Institution < ApplicationRecord
  include Filterable

  scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
  scope :entity_id_like, ->(like) { where("entity_id like ?", "%#{like}%") }

  validates :identifier, presence: true, allow_blank: false, uniqueness: true
  validates :name, presence: true, allow_blank: false
  # validates :entity_id, presence: true, allow_blank: false
  # validates :site, presence: true, allow_blank: false
  # validates :login, presence: true, allow_blank: false

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
    rescue StandardError => e
      errors.add(:identifier, "create lessee #{identifier} fail! #{e}")
      throw(:abort)
    end
  end

  before_destroy do
    if lessee.products.present?
      errors.add(:base, "institution has #{lessee.products.count} associated products!")
      throw(:abort)
    end
    if grants.present?
      errors.add(:base, "institution has #{grants.count} associated grants!")
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
    lessee&.products.blank? && grants.blank?
  end

  def shibboleth?
    entity_id.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end

  def grants
    Grant.agent_grants(self)
  end

  def products
    products = []
    products << lessee.products
    grants.each do |grant|
      next unless grant.resource_type == 'Product'
      products << Product.find(grant.resource_id)
    end
    products.flatten.uniq
  end

  def components
    components = []
    products.each do |product|
      components << product.components
    end
    grants.each do |grant|
      next unless grant.resource_type == 'Component'
      components << Component.find(grant.resource_id)
    end
    components.flatten.uniq
  end

  def agent_type
    :Institution
  end

  def agent_id
    id
  end
end
