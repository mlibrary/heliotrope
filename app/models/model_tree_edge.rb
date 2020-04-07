# frozen_string_literal: true

class ModelTreeEdge < ApplicationRecord
  validates :parent_noid, presence: true, format: { with: /\A[[:alnum:]]{9}\z/, message: 'must be 9 alphanumeric characters' }
  validates :child_noid, presence: true, format: { with: /\A[[:alnum:]]{9}\z/, message: 'must be 9 alphanumeric characters' }, uniqueness: true
  validate :prohibit_loops

  def prohibit_loops
    if parent_noid == child_noid
      errors.add(:parent_noid, 'can not be child of self')
    else
      child_parent = ModelTreeEdge.find_by(child_noid: parent_noid)
      errors.add(:parent_noid, 'can not be child of child') if child_parent.present? && child_parent.parent_noid == child_noid
    end
  end
end
