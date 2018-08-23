# frozen_string_literal: true

class Institution < ApplicationRecord
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
    if lessee.groupings.present?
      errors.add(:base, "institution is associated with #{lessee.groupings.count} groupings!")
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
    !(lessee? && (lessee.products.present? || lessee.groupings.present?))
  end

  def lessee?
    lessee.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end

  def shibboleth?
    entity_id.present?
  end
end
