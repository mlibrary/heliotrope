# frozen_string_literal: true

module Greensub
  class Institution < ApplicationRecord
    include Licensee
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :display_name_like, ->(like) { where("display_name like ?", "%#{like}%") }
    scope :entity_id_like, ->(like) { where("entity_id like ?", "%#{like}%") }
    scope :security_domain_like, ->(like) { where("security_domain like ?", "%#{like}%") }
    scope :for_entity_id, ->(entity_id) { where(entity_id: entity_id) }
    scope :containing_dlps_institution_id, ->(dlps_institution_id) { joins(:institution_affiliations).merge(InstitutionAffiliation.for_dlps_institution_id(dlps_institution_id)).distinct }

    validates :identifier, presence: true, allow_blank: false, uniqueness: { case_sensitive: true }, numericality: { only_integer: true }
    validates :name, presence: true, allow_blank: false
    validates :display_name, presence: true, allow_blank: false
    validates :security_domain, uniqueness: true, allow_blank: true

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
      entity_id.present? && in_common
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

    def logo
      # always prefer horizontal logo if set
      expected_logo_path = if horizontal_logo.present?
                             File.join('img', 'institutions', 'horizontal', horizontal_logo)
                           elsif vertical_logo.present?
                             File.join('img', 'institutions', 'vertical', vertical_logo)
                           end

      # Plenty of scope for the logo DB entries and actual images to be out-of-sync. Hence all the file checking here.
      # The latter are uploaded to the GitHub repo while the former use the Fulcrum dashboard Institutions edit form.
      # Maybe down the line we'll use CarrierWave for them, though that usually comes with its own issues.

      if expected_logo_path.present? && File.exist?(Rails.root.join('public', expected_logo_path).to_s)
        # adds a preceding slash, which is needed to use a public path in views
        File.join('', expected_logo_path)
      else
        Rails.logger.info "Institution logo listed in DB does not exist in public folder: #{expected_logo_path}"
        nil
      end
    end

    private

      def type
        @type ||= /^Greensub::(.+$)/.match(self.class.to_s)[1].to_sym
      end
  end
end
