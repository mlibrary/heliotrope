# frozen_string_literal: true

class HandleDeposit < ApplicationRecord
  include Filterable

  scope :handle_like, ->(like) { where("handle like ?", "%#{like}%") }
  scope :url_value_like, ->(like) { where("url_value like ?", "%#{like}%") }
  scope :action_like, ->(like) { where("action like ?", "%#{like}%") }
  scope :verified_like, ->(like) { where("verified like ?", "%#{like}%") }
end
