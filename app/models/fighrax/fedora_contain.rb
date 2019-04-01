# frozen_string_literal: true

module Fighrax
  class FedoraContain < ApplicationRecord
    include Filterable

    scope :uri_like, ->(like) { where("uri like ?", "%#{like}%") }
    scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
    scope :model_like, ->(like) { where("model like ?", "%#{like}%") }
    scope :title_like, ->(like) { where("title like ?", "%#{like}%") }
  end
end
