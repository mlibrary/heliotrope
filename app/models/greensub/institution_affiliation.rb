# frozen_string_literal: true

module Greensub
  class InstitutionAffiliation < ApplicationRecord
    AFFILIATIONS = %w[member alum walk-in].freeze

    belongs_to :institution

    include Filterable

    scope :institution_id_like, ->(like) { where("institution_id like ?", "%#{like}%") }
    scope :dlps_institution_id_like, ->(like) { where("dlps_institution_id like ?", "%#{like}%") }
    scope :affiliation_like, ->(like) { where("affiliation like ?", "%#{like}%") }

    validates :institution_id, presence: true, allow_blank: false
    validates :dlps_institution_id, presence: true, allow_blank: false
    validates :affiliation, presence: true, allow_blank: false
    validates :affiliation, inclusion: { in: AFFILIATIONS }

    def self.affiliations
      AFFILIATIONS
    end
  end
end