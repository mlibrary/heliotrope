module HydraEditor
  module Form
    module Permissions
      extend ActiveSupport::Concern

      module ClassMethods
        def build_permitted_params
          permitted = super
          permitted << { permissions_attributes: [:type, :name, :access, :id, :_destroy] }
          permitted
        end
      end

      # This is required so that fields_for will draw a nested form.
      # See ActionView::Helpers#nested_attributes_association?
      #   https://github.com/rails/rails/blob/a04c0619617118433db6e01b67d5d082eaaa0189/actionview/lib/action_view/helpers/form_helper.rb#L1890
      delegate :permissions_attributes=, to: :model
    end
  end
end
