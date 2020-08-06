# frozen_string_literal: true

module Greensub
  class Component < ApplicationRecord
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }

    has_many :components_products # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :products, through: :components_products,
                                 after_remove: :reindex_component_product,
                                 after_add: :reindex_component_product

    validates :identifier, presence: true, allow_blank: false, uniqueness: true
    validates :noid, presence: true, allow_blank: false

    before_destroy do
      if products.present?
        errors.add(:base, "component has #{products.count} associated products!")
        throw(:abort)
      end
      if grants?
        errors.add(:base, "component has at least one associated grant!")
        throw(:abort)
      end
    end

    def update?
      true
    end

    def destroy?
      products.blank? && !grants?
    end

    def not_products
      Product.where.not(id: products.map(&:id))
    end

    def not_products_like(like = '')
      Product.where.not(id: products.map(&:id)).where("identifier like ?", "%#{like}%").order(:identifier)
    end

    def noid
      return @noid if @noid.present?
      @noid = super
    end

    def monograph?
      Sighrax.from_noid(noid).is_a?(Sighrax::Monograph)
    end

    def file_set?
      Sighrax.from_noid(noid).is_a?(Sighrax::Asset)
    end

    def grants?
      Authority.resource_grants?(self)
    end

    def resource_type
      type
    end

    def resource_id
      id
    end

    # If this gets called via the has_many components_products on like:
    # > component.products.delete(product)
    # > component.products << product
    # then the product gets passed as a param, which we don't actually use.
    def reindex_component_product(_product)
      ReindexJob.perform_later(noid)
    end

    private

      def type
        @type ||= /^Greensub::(.+$)/.match(self.class.to_s)[1].to_sym
      end
  end
end
