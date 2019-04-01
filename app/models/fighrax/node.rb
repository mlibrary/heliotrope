# frozen_string_literal: true

module Fighrax
  class Node
    private_class_method :new

    attr_reader :uri
    attr_reader :jsonld

    # Class Methods

    def self.null_node(uri = ActiveFedora::Base.id_to_uri('null_uri'))
      NullNode.send(:new, uri)
    end

    # Instance Methods

    def valid?
      !instance_of?(NullNode)
    end

    def resource_type
      type
    end

    def resource_id
      noid
    end

    def resource_token
      @resource_token ||= resource_type.to_s + ':' + resource_id.to_s
    end

    def parent
      self.class.null_node
    end

    def noid
      @noid = ActiveFedora::Base.uri_to_id(uri)
    end

    def model
      @model ||= @jsonld['hasModel'] || ''
    end

    def title
      @title ||= jsonld['title'] || @uri
    end

    protected

      def type
        @type ||= /^Fighrax::(.+$)/.match(self.class.to_s)[1].to_sym
      end

    private

      def initialize(uri, jsonld)
        @uri = uri
        @jsonld = jsonld
      end
  end

  class NullNode < Node
    private_class_method :new

    private

      def initialize(uri)
        super(uri, {})
      end
  end
end
