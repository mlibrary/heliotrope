# frozen_string_literal: true

module Hyrax
  class FileSetsController < ApplicationController
    include Hyrax::FileSetsControllerBehavior

    self.form_class = ::Heliotrope::FileSetEditForm
  end
end
