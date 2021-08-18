# frozen_string_literal: true

module Greensub
  class License < ApplicationRecord
    TYPES = %w[full read].freeze

    attr_accessor :individual_id
    attr_accessor :institution_id

    belongs_to :product

    include Filterable
    scope :type_like, ->(like) { where("type like ?", "%#{like}%") }
    scope :licensee_type_like, ->(like) { where("licensee_type like ?", "#{like}") }
    scope :licensee_id_like, ->(like) { where("licensee_id like ?", "#{like}") }
    scope :product_id_like, ->(like) { where("product_id like ?", "#{like}") }

    validates :type, presence: true, inclusion: { in: %w[Greensub::FullLicense Greensub::ReadLicense] }
    validates :licensee_type, presence: true, inclusion: { in: %w[Greensub::Individual Greensub::Institution] }
    validates :licensee_id, presence: true
    validates :product_id, presence: true
    validates :type, uniqueness: { scope: [:licensee_type, :licensee_id, :product_id] }

    has_many :license_affiliations, dependent: :restrict_with_error
    alias_attribute :affiliations, :license_affiliations

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
      grants.blank? && license_affiliations.empty?
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

    def member?
      license_affiliations.pluck(:affiliation).include? 'member'
    end

    def alum?
      license_affiliations.pluck(:affiliation).include? 'alum'
    end

    def walk_in?
      license_affiliations.pluck(:affiliation).include? 'walk-in'
    end

    def active?
      grants?
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
