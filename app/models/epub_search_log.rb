# frozen_string_literal: true

class EpubSearchLog < ApplicationRecord
  include Filterable

  scope :query_like, ->(like) { where("query like ?", "%#{like}%") }
  scope :created_like, ->(like) { where("created_at like ?", "%#{like}%") }
  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :time_like, ->(like) { where("time like ?", "%#{like}%") }
  scope :hits_like, ->(like) { where("hits like ?", "%#{like}%") }
end
