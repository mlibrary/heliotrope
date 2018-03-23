# frozen_string_literal: true

class Institution < ApplicationRecord
  validates :key, presence: true, allow_blank: false
  validates :name, presence: true, allow_blank: false
  validates :site, presence: true, allow_blank: false
  validates :login, presence: true, allow_blank: false

  def lessee
    Lessee.find_by(identifier: key)
  end
end
