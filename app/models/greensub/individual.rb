# frozen_string_literal: true

module Greensub
  class Individual < ApplicationRecord
    include Filterable

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :email_like, ->(like) { where("identifier like ?", "%#{like}%") }

    validates :identifier, presence: true, allow_blank: false, uniqueness: true
    validates :name, presence: true, allow_blank: false
    validates :email, presence: true, allow_blank: false, uniqueness: true

    before_validation(on: :update) do
      if identifier_changed?
        errors.add(:identifier, "individual identifier can not be changed!")
        throw(:abort)
      end
    end

    before_destroy do
      if products.present?
        errors.add(:base, "individual has #{products.count} associated products!")
        throw(:abort)
      end
      if grants?
        errors.add(:base, "individual has at least one associated grant!")
        throw(:abort)
      end
    end

    def update?
      true
    end

    def destroy?
      products.blank? && !grants?
    end

    def products
      Greensub.subscriber_products(self)
    end

    def grants?
      Authority.agent_grants?(self)
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
