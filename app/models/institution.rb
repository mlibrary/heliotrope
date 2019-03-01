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

  before_validation(on: :update) do
    if identifier_changed?
      errors.add(:identifier, "institution identifier can not be changed!")
      throw(:abort)
    end
  end

  before_destroy do
    if products.present?
      errors.add(:base, "institution has #{products.count} associated products!")
      throw(:abort)
    end
    if grants?
      errors.add(:base, "institution has at least one associated grant!")
      throw(:abort)
    end
  end

  def update?
    true
  end

  def destroy?
    products.blank? && !grants?
  end

  def shibboleth?
    entity_id.present?
  end

  def products
    Greensub.subscriber_products(self)
  end

  def grants?
    Authority.agent_grants?(self)
  end

  def agent_type
    :Institution
  end

  def agent_id
    id
  end
end
