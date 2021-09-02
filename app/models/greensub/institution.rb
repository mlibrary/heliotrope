# frozen_string_literal: true

module Greensub
  class Institution < ApplicationRecord
    include Licensee
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :entity_id_like, ->(like) { where("entity_id like ?", "%#{like}%") }
    scope :for_entity_id, ->(entity_id) { where(entity_id: entity_id) }
    scope :containing_dlps_institution_id, ->(dlps_institution_id) { joins(:institution_affiliations).merge(InstitutionAffiliation.for_dlps_institution_id(dlps_institution_id)).distinct }

    validates :identifier, presence: true, allow_blank: false, uniqueness: true, numericality: { only_integer: true }
    validates :name, presence: true, allow_blank: false

    has_many :licenses, as: :licensee, dependent: :restrict_with_error
    has_many :institution_affiliations, dependent: :restrict_with_error
    alias_attribute :affiliations, :institution_affiliations

    before_validation(on: :update) do
      if identifier_changed?
        errors.add(:identifier, "institution identifier can not be changed!")
        throw(:abort)
      end
    end

    before_destroy do
      if grants?
        errors.add(:base, "institution has associated grant!")
        throw(:abort)
      end
    end

    def update?
      true
    end

    def destroy?
      affiliations.empty? && !licenses? && !grants?
    end

    def shibboleth?
      entity_id.present?
    end

    def dlps_institution_ids
      institution_affiliations.pluck(:dlps_institution_id)
    end

    def agent_type
      type
    end

    def agent_id
      id
    end

    private

      def type
        @type ||= /^Greensub::(.+$)/.match(self.class.to_s)[1].to_sym
      end
  end
end
