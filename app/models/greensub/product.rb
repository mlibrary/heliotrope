# frozen_string_literal: true

module Greensub
  class Product < ApplicationRecord
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :purchase_like, ->(like) { where("purchase like ?", "%#{like}%") }

    has_many :components_products # rubocop:disable Rails/HasManyOrHasOneDependent
    has_many :components, through: :components_products

    validates :identifier, presence: true, allow_blank: false, uniqueness: true
    validates :name, presence: true, allow_blank: false
    # validates :purchase, presence: true, allow_blank: false

    before_destroy do
      if components.present?
        errors.add(:base, "product has #{components.count} associated components!")
        throw(:abort)
      end
      if grants?
        errors.add(:base, "product has at least one associated grant!")
        throw(:abort)
      end
    end

    def update?
      true
    end

    def destroy?
      components.blank? && !grants?
    end

    def not_components
      Component.where.not(id: components.map(&:id))
    end

    def not_components_like(like = '')
      Component.where.not(id: components.map(&:id)).where("identifier like ?", "%#{like}%").order(:identifier)
    end

    def individuals
      @individuals ||= subscribers.map { |s| s if s.is_a?(Individual) }.compact
    end

    def institutions
      @institutions ||= subscribers.map { |s| s if s.is_a?(Institution) }.compact
    end

    def subscribers
      Greensub.product_subscribers(self)
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

    private
      def type
        @type ||= /^Greensub::(.+$)/.match(self.class.to_s)[1].to_sym
      end
  end
end
