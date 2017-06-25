# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Asset`

module Hyrax
  class AssetsController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::Asset

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::AssetPresenter
  end
end
