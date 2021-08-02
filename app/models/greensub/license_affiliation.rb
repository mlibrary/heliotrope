# frozen_string_literal: true

module Greensub
  class LicenseAffiliation < ApplicationRecord
    AFFILIATIONS = InstitutionAffiliation::AFFILIATIONS

    belongs_to :license

    include Filterable

    scope :license_id_like, ->(like) { where("license_id like ?", "%#{like}%") }
    scope :affiliation_like, ->(like) { where("affiliation like ?", "%#{like}%") }

    validates :license_id, presence: true, allow_blank: false
    validates :affiliation, presence: true, allow_blank: false, inclusion: { in: AFFILIATIONS }

    def self.affiliations
      AFFILIATIONS
    end
  end
end
