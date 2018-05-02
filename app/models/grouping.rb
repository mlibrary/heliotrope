# frozen_string_literal: true

class Grouping < ApplicationRecord
  has_many :groupings_lessees
  has_many :lessees, through: :groupings_lessees

  validates :identifier, presence: true, allow_blank: false

  before_validation(on: :create) do
    if Lessee.find_by(identifier: identifier).present?
      errors.add(:base, "lessee identifier #{identifier} exists!")
      throw(:abort)
    end
  end

  before_create do
    Lessee.create!(identifier: identifier)
  end

  after_destroy do
    lessee.destroy!
  end

  def lessee?
    lessee.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end

  def not_lessees
    # TODO: Filter out self.lessee from result
    Lessee.where.not(id: lessees.map(&:id))
  end
end
