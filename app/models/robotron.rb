# frozen_string_literal: true

class Robotron < ApplicationRecord
  include Filterable

  scope :ip_like, ->(like) { where("ip like ?", "%#{like}%") }
  scope :hits_like, ->(like) { where("hits like ?", "%#{like}%") }
  scope :updated_at_like, ->(like) { where("updated_at like ?", "%#{like}%") }

  validates :ip, presence: true, allow_blank: false, uniqueness: true
end
