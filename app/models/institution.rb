# frozen_string_literal: true

class Institution < ApplicationRecord
  validates :identifier, presence: true, allow_blank: false
  validates :name, presence: true, allow_blank: false
  validates :site, presence: true, allow_blank: false
  validates :login, presence: true, allow_blank: false

  def lessee?
    lessee.present?
  end

  def lessee
    Lessee.find_by(identifier: identifier)
  end
end
