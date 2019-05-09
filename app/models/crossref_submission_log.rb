# frozen_string_literal: true

class CrossrefSubmissionLog < ApplicationRecord
  validates :status, inclusion: { in: %w[submitted success error abandoned] }
end
