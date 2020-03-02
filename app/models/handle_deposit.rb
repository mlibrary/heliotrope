# frozen_string_literal: true

class HandleDeposit < ApplicationRecord
  include Filterable

  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :action_like, ->(like) { where("action like ?", "%#{like}%") }
  scope :verified_like, ->(like) { where("verified like ?", "%#{like}%") }
end
