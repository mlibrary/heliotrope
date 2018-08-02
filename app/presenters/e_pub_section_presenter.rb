# frozen_string_literal: true

class EPubSectionPresenter < ApplicationPresenter
  delegate :title, :level, :cfi, :downloadable?, to: :@section

  def initialize(section)
    @section = section
  end
end
