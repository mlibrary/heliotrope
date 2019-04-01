# frozen_string_literal: true

require_dependency 'fighrax/access_control'
require_dependency 'fighrax/admin_set'
require_dependency 'fighrax/file'
require_dependency 'fighrax/file_set'
require_dependency 'fighrax/model'
require_dependency 'fighrax/monograph'
require_dependency 'fighrax/node'

module Fighrax
  class << self
    def factory(uri)
      uri = uri&.to_s
      return Node.null_node(uri) unless ValidationService.valid_uri?(uri)

      jsonld = begin
        fedora_node(uri).jsonld
      rescue StandardError => e
        Rails.logger.error(e)
        nil
      end
      return Node.null_node(uri) if jsonld.blank?

      model_type = jsonld['hasModel']
      return Node.send(:new, uri, jsonld) if model_type.blank?
      model_factory(uri, jsonld, model_type)
    end

    private

      def fedora_node(uri)
        node = FedoraNode.find_by(uri: uri)
        return node if node.present?

        jsonld = RestfulFedora::Service.new.node(uri)

        node = FedoraNode.new
        node.uri = uri
        node.noid = ActiveFedora::Base.uri_to_id(uri)
        node.jsonld = jsonld
        node.model = jsonld['hasModel'] || ''
        node.save
        node.reload

        node
      end

      def model_factory(uri, jsonld, model_type)
        if    /^Hydra::AccessControl$/i.match?(model_type)
          AccessControl.send(:new, uri, jsonld)
        elsif /^AdminSet$/i.match?(model_type)
          AdminSet.send(:new, uri, jsonld)
        elsif /^File$/i.match?(model_type)
          File.send(:new, uri, jsonld)
        elsif /^FileSet$/i.match?(model_type)
          FileSet.send(:new, uri, jsonld)
        elsif /^Monograph$/i.match?(model_type)
          Monograph.send(:new, uri, jsonld)
        else
          Model.send(:new, uri, jsonld)
        end
      end
  end
end
