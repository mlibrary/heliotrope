# frozen_string_literal: true

module Greensub
  class Institution < ApplicationRecord
    include Filterable
    include Licensee

    scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
    scope :name_like, ->(like) { where("name like ?", "%#{like}%") }
    scope :entity_id_like, ->(like) { where("entity_id like ?", "%#{like}%") }

    validates :identifier, presence: true, allow_blank: false, uniqueness: true
    validates :name, presence: true, allow_blank: false
    # validates :entity_id, presence: true, allow_blank: false
    # validates :site, presence: true, allow_blank: false
    # validates :login, presence: true, allow_blank: false

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
      !grants?
    end

    def shibboleth?
      entity_id.present?
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
