# frozen_string_literal: true

class Grouping < ApplicationRecord
  has_many :groupings_lessees
  has_many :lessees, after_add: :remove_groupings, through: :groupings_lessees

  validates :identifier, presence: true, allow_blank: false, uniqueness: true

  before_validation(on: :create) do
    if Lessee.find_by(identifier: identifier).present?
      errors.add(:identifier, "lessee identifier #{identifier} exists!")
      throw(:abort)
    end
  end

  before_validation(on: :update) do
    if identifier_changed?
      errors.add(:identifier, "grouping identifier can not be changed!")
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
      errors.add(:base, "grouping has #{lessee.products.count} associated products!")
      throw(:abort)
    end
    if lessees.present?
      errors.add(:base, "grouping has #{lessees.count} associated lessees!")
      throw(:abort)
    end
  end

  after_destroy do
    lessee.destroy!
  end

  def update?
    false
  end

  def destroy?
    !((lessee? && lessee.products.present?) || lessees.present?)
  end

  def lessee?
    lessee.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end

  def not_lessees
    Lessee.where.not(id: lessees.map(&:id)).reject(&:grouping?)
  end

  private

    def remove_groupings(added_lessees)
      groupings = [added_lessees].select(&:grouping?)
      lessees.delete(groupings)
    end
end
