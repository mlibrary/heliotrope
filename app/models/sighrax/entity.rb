# frozen_string_literal: true

module Sighrax
  class Entity
    private_class_method :new

    attr_reader :noid

    def self.null_entity(noid = nil)
      noid = 'null_noid' if noid.blank?
      NullEntity.send(:new, noid)
    end

    def resource_id
      noid
    end

    def resource_token
      resource_type.to_s + ':' + resource_id.to_s
    end

    def resource_type
      type
    end

    def title
      noid
    end

    def uri
      ActiveFedora::Base.id_to_uri(noid)
    end

    def valid?
      !instance_of?(NullEntity)
    end

    def ==(other)
      noid == other.noid
    end

    protected

      attr_reader :data

      def type
        @type ||= /^Sighrax::(.+$)/.match(self.class.to_s)[1].to_sym
      end

      def scalar(key)
        vector(key).first
      end

      def vector(key)
        Array(data[key])
      end

    private

      def initialize(noid, data)
        @noid = noid
        @data = data
      end
  end
end
