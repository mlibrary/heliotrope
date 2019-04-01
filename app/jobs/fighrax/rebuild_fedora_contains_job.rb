# frozen_string_literal: true

module Fighrax
  class RebuildFedoraContainsJob < ApplicationJob
    def perform
      FedoraContain.delete_all
      FedoraNode.delete_all
      RestfulFedora::Service.new.contains.each do |uri|
        node = Fighrax.factory(uri)

        contain = FedoraContain.new
        contain.uri = node.uri
        contain.noid = node.noid
        contain.model = node.model
        contain.title = node.title
        contain.fedora_node_id = FedoraNode.find_by(uri: node.uri).id
        contain.save
      end
    end
  end
end
