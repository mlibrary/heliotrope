# frozen_string_literal: true

class PDFIntervalRecord < ApplicationRecord
  validates :noid, presence: true, allow_blank: false, uniqueness: true
  validates :data, presence: true, allow_blank: false
end
