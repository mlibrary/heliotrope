# frozen_string_literal: true

module Blacklight::AccessControls
  module PermissionsQuery
    extend ActiveSupport::Concern

    def permissions_doc(pid)
      doc = cache.get(pid)
      unless doc
        doc = get_permissions_solr_response_for_doc_id(pid)
        cache.put(pid, doc)
      end
      doc
    end

    # This is only valid for, and should only be used for blacklight 6
    def permissions_document_class
      blacklight_config.document_model
    end

    protected

    def blacklight_config
      CatalogController.blacklight_config
    end

    # a solr query method
    # retrieve a solr document, given the doc id
    # Modeled on Blacklight::SolrHelper.get_permissions_solr_response_for_doc_id
    # @param [String] id of the documetn to retrieve
    # @param [Hash] extra_controller_params (optional)
    def get_permissions_solr_response_for_doc_id(id = nil, extra_controller_params = {})
      raise Blacklight::Exceptions::RecordNotFound, 'The application is trying to retrieve permissions without specifying an asset id' if id.nil?
      solr_opts = permissions_solr_doc_params(id).merge(extra_controller_params)
      response = Blacklight.default_index.connection.get('select', params: solr_opts)

      # Passing :blacklight_config is required for Blacklight 7, :document_model is required for Blacklight 6
      solr_response = Blacklight::Solr::Response.new(response, solr_opts,
                                                     blacklight_config: blacklight_config,
                                                     document_model: permissions_document_class)

      raise Blacklight::Exceptions::RecordNotFound, "The solr permissions search handler didn't return anything for id \"#{id}\"" if solr_response.docs.empty?
      solr_response.docs.first
    end

    #
    #  Solr integration
    #

    # returns a params hash with the permissions info for a single solr document
    # If the id arg is nil, then the value is fetched from params[:id]
    # This method is primary called by the get_permissions_solr_response_for_doc_id method.
    # Modeled on Blacklight::SolrHelper.solr_doc_params
    # @param [String] id of the documetn to retrieve
    def permissions_solr_doc_params(id = nil)
      id ||= params[:id]
      # just to be consistent with the other solr param methods:
      {
        qt: :permissions,
        id: id # this assumes the document request handler will map the 'id' param to the unique key field
      }
    end
  end
end
