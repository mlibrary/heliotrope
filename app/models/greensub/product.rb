# frozen_string_literal: true

module Greensub
  class Product < ApplicationRecord
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :purchase_like, ->(like) { where("purchase like ?", "%#{like}%") }

    scope :containing_monograph, ->(noid) { joins(:components).merge(Component.for_noid(noid)) }

    has_many :licenses, dependent: :restrict_with_error
    has_many :components_products, dependent: :restrict_with_error
    has_many :components, through: :components_products, dependent: :restrict_with_error,
                                   after_remove: :reindex_component_product,
                                   after_add: :reindex_component_product

    validates :identifier, presence: true, allow_blank: false, uniqueness: true
    validates :name, presence: true, allow_blank: false

    before_destroy do
      if grants?
        errors.add(:base, "Cannot delete record because dependent grant exist")
        throw(:abort)
      end
    end

    def update?
      true
    end

    def destroy?
      components.blank? && !licensees? && !grants?
    end

    def not_components
      Component.where.not(id: components.map(&:id))
    end

    def not_components_like(like = '')
      Component.where.not(id: components.map(&:id)).where("identifier like ?", "%#{like}%").order(:identifier)
    end

    def licensees?
      individuals? || institutions?
    end

    def licensees
      individuals + institutions
    end

    def individuals?
      individuals.present?
    end

    def individuals
      Individual.where(id: licenses.where(licensee_type: 'Greensub::Individual').pluck(:licensee_id)).compact
    end

    def institutions?
      institutions.present?
    end

    def institutions
      Institution.where(id: licenses.where(licensee_type: 'Greensub::Institution').pluck(:licensee_id)).compact
    end

    def licenses?
      licenses.present?
    end

    def grants?
      grants.present?
    end

    def grants
      Checkpoint::DB::Grant.where(resource_type: resource_type.to_s, resource_id: resource_id.to_s)
    end

    def resource_type
      type
    end

    def resource_id
      id
    end

    # If this gets called via the has_many components_products on add or delete like:
    # > product.components << component
    # > product.components.delete(component)
    # then we need to reindex the Monograph to save/delete the product
    def reindex_component_product(component)
      ReindexJob.perform_later(component.noid)
    end

    private

      def type
        @type ||= /^Greensub::(.+$)/.match(self.class.to_s)[1].to_sym
      end
  end
end
