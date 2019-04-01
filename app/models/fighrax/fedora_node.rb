# frozen_string_literal: true

module Fighrax
  class FedoraNode < ApplicationRecord
    include Filterable

    scope :uri_like, ->(like) { where("uri like ?", "%#{like}%") }
    scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
    scope :model_like, ->(like) { where("model like ?", "%#{like}%") }
    scope :jsonld_like, ->(like) { where("jsonld like ?", "%#{like}%") }
  end
end
