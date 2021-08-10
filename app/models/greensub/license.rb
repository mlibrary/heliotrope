# frozen_string_literal: true

module Greensub
  class License < ApplicationRecord
    TYPES = %w[full read].freeze

    belongs_to :product

    include Filterable
    scope :type_like, ->(like) { where("type like ?", "%#{like}%") }
    scope :licensee_id_like, ->(like) { where("licensee_id like ?", "%#{like}%") }
    scope :product_id_like, ->(like) { where("product_id like ?", "%#{like}%") }

    validates :type, presence: true, inclusion: { in: %w[Greensub::FullLicense Greensub::ReadLicense] }

    has_many :license_affiliations, dependent: :restrict_with_error

    # temporary! TODO: HELIO-3994
    #
    # before_validation(on: :update) do
    #   if licensee_type_changed? || licensee_id_changed?
    #     errors.add(:licensee, "can not be changed!")
    #     throw(:abort)
    #   end
    #   if product_id_changed?
    #     errors.add(:product, "can not be changed!")
    #     throw(:abort)
    #   end
    # end

    before_destroy do
      if grants?
        errors.add(:base, "license has associated grant!")
        throw(:abort)
      end
    end

    def entitlements
      []
    end

    def allows?(action)
      entitlements.include?(action)
    end

    def update?
      grants.blank?
    end

    def destroy?
      grants.blank?
    end

    def credential_type
      :License
    end

    def credential_id
      id
    end

    def to_credential
      LicenseCredential.new(self.id)
    end

    def label
      @label ||= /^Greensub::(.+)(License$)/.match(self.class.to_s)[1]
    end

    def individual?
      licensee.is_a?(Greensub::Individual)
    end

    def institution?
      licensee.is_a?(Greensub::Institution)
    end

    private

      def grants?
        grants.present?
      end

      def grants
        @grants ||= Checkpoint::DB::Grant.where(credential_type: 'License', credential_id: credential_id.to_i)
      end
  end
end
