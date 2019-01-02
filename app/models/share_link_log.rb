# frozen_string_literal: true

class ShareLinkLog < ApplicationRecord
  include Filterable

  scope :ip_address_like, ->(like) { where("ip_address like ?", "%#{like}%") }
  scope :institution_like, ->(like) { where("institution like ?", "%#{like}%") }
  scope :press_like, ->(like) { where("subdomain like ?", "%#{like}%") }
  scope :title_like, ->(like) { where("title like ?", "%#{like}%") }
  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  scope :token_like, ->(like) { where("token like ?", "%#{like}%") }
  scope :action_like, ->(like) { where("token like ?", "%#{like}%") }
  scope :created_like, ->(like) { where("created_at like ?", "%#{like}") }
end
