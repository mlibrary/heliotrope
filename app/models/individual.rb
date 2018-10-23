# frozen_string_literal: true

class Individual < ApplicationRecord
  include Filterable

  scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :name_like, ->(like) { where("identifier like ?", "%#{like}%") }
  scope :email_like, ->(like) { where("identifier like ?", "%#{like}%") }

  validates :identifier, presence: true, allow_blank: false, uniqueness: true
  validates :email, presence: true, allow_blank: false, uniqueness: true

  before_destroy do
    if policies.present?
      errors.add(:base, "individual has #{policies.count} associated policies!")
      throw(:abort)
    end
  end

  def destroy?
    policies.blank?
  end

  def policies
    Policy.agent_policies(self)
  end
end
