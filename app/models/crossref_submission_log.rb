# frozen_string_literal: true

class CrossrefSubmissionLog < ApplicationRecord
  validates :status, inclusion: { in: %w[submitted received error] }
end
