# frozen_string_literal: true

module Blacklight
  module AccessControls
    # This is behavior for the catalog controller.
    module Catalog
      extend ActiveSupport::Concern

      # Controller "before" filter for enforcing access controls on show actions.
      # @param [Hash] _opts (optional, not currently used)
      def enforce_show_permissions(_opts = {})
        permissions = current_ability.permissions_doc(params[:id])
        unless can? :read, permissions
          raise Blacklight::AccessControls::AccessDenied.new('You do not have sufficient access privileges to read this document, which has been marked private.', :read, params[:id])
        end
        permissions
      end

      # This will work for BL 6, but will need to move to SearchService in BL 7
      def search_builder
        Blacklight::AccessControls::SearchBuilder.new(self, ability: current_ability)
      end
    end
  end
end
