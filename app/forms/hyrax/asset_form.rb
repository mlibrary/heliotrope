# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Asset`
module Hyrax
  class AssetForm < Hyrax::Forms::WorkForm
    self.model_class = ::Asset
    self.terms += [:resource_type]
  end
end
