# frozen_string_literal: true

class EpubSearchLog < ApplicationRecord
  include Filterable

  scope :query_like, ->(like) { where("query like ?", "%#{like}%") }
  scope :created_like, ->(like) { where("created_at like ?", "%#{like}%") }
  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :time_like, ->(like) { where("time like ?", "%#{like}%") }
  scope :hits_like, ->(like) { where("hits like ?", "%#{like}%") }
  scope :press_like, ->(like) { where("press like ?", "%#{like}%") }
  scope :user_like, ->(like) { where("user like ?", "%#{like}%") }
  scope :session_id_like, ->(like) { where("session_id like ?", "%#{like}%") }

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << self.attribute_names.reject { |r| r == "search_results" || r == "updated_at" }

      all.find_each do |record|
        csv << record.attributes.reject! { |k, _v| k == "search_results" || k == "updated_at" }.values
      end
    end
  end
end
