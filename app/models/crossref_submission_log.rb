# frozen_string_literal: true

class CrossrefSubmissionLog < ApplicationRecord
  include Filterable

  validates :status, inclusion: { in: %w[submitted success error abandoned] }

  scope :doi_batch_id_like, ->(like) { where("doi_batch_id like ?", "%#{like}%") }
  scope :status_like, ->(like) { where("status like ?", "%#{like}%") }
  scope :file_name_like, ->(like) { where("file_name like ?", "%#{like}%") }
  scope :created_at_like, ->(like) { where("created_at like ?", "%#{like}%") }
  scope :updated_at_like, ->(like) { where("updated_at like ?", "%#{like}%") }
end
