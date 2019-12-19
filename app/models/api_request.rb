# frozen_string_literal: true

class APIRequest < ApplicationRecord
  include Filterable

  scope :user_id_like, ->(like) { where("user_id like ?", "%#{like}%") }
  scope :action_like, ->(like) { where("action like ?", "%#{like}%") }
  scope :path_like, ->(like) { where("path like ?", "%#{like}%") }
  scope :params_like, ->(like) { where("params like ?", "%#{like}%") }
  scope :status_like, ->(like) { where("status like ?", "%#{like}%") }
  scope :exception_like, ->(like) { where("exception like ?", "%#{like}%") }
  scope :created_at_like, ->(like) { where("created_at like ?", "%#{like}%") }

  belongs_to :user, optional: true
end
