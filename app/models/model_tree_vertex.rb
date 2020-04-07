# frozen_string_literal: true

class ModelTreeVertex < ApplicationRecord
  validates :noid, presence: true, format: { with: /\A[[:alnum:]]{9}\z/, message: 'must be 9 alphanumeric characters' }, uniqueness: true
end
