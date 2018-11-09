# frozen_string_literal: true

module Sighrax
  class Entity
    private_class_method :new

    attr_reader :noid

    # Class Methods

    def self.null_entity(noid = 'null_noid')
      NullEntity.send(:new, noid)
    end

    # Instance Methods

    def valid?
      !instance_of?(NullEntity)
    end

    def resource_type
      type
    end

    def resource_id
      noid
    end

    def title
      entity["title_tesim"]&.first || noid
    end

    protected

      attr_reader :entity

      def type
        @type ||= /(^.*\:\:)(.+$)/.match(self.class.to_s)[2].to_sym
      end

    private

      def initialize(noid, entity)
        @noid = noid
        @entity = entity
      end
  end

  class NullEntity < Entity
    private_class_method :new

    private

      def initialize(noid)
        super(noid, {})
      end
  end
end
