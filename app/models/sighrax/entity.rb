# frozen_string_literal: true

module Sighrax
  class Entity
    private_class_method :new

    attr_reader :noid
    attr_reader :data

    # Class Methods

    def self.null_entity(noid = 'null_noid')
      NullEntity.send(:new, noid)
    end

    # Instance Methods

    def valid?
      !instance_of?(NullEntity)
    end

    def uri
      ActiveFedora::Base.id_to_uri(noid)
    end

    def resource_type
      type
    end

    def resource_id
      noid
    end

    def resource_token
      resource_type.to_s + ':' + resource_id.to_s
    end

    def parent
      self.class.null_entity
    end

    def title
      data['title_tesim']&.first || noid
    end

    protected

      def type
        @type ||= /^Sighrax::(.+$)/.match(self.class.to_s)[1].to_sym
      end

    private

      def initialize(noid, data)
        @noid = noid
        @data = data
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
