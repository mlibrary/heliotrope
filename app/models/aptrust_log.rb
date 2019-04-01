# frozen_string_literal: true

class AptrustLog < ApplicationRecord
  include Filterable

  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :where_like, ->(like) { where("where like ?", "%#{like}%") }
  scope :stage_like, ->(like) { where("stage like ?", "%#{like}%") }
  scope :status_like, ->(like) { where("status like ?", "%#{like}%") }
  scope :action_like, ->(like) { where("action like ?", "%#{like}%") }
end
