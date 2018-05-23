# frozen_string_literal: true

module Hyrax
  module My
    # Search builder for things that the current user has edit access to
    # Heliotrope Hyrax override
    # @abstract
    class SearchBuilder < ::SearchBuilder
      # Check for edit access
      include Hyrax::My::SearchBuilderBehavior
      self.default_processor_chain += [:show_all_edit_access]
      self.default_processor_chain -= [:only_active_works]

      def show_all_edit_access(solr_parameters)
        roles = current_user.groups.join(",")
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "{!terms f=edit_access_group_ssim}#{roles}"
      end
    end
  end
end
