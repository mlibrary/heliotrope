# frozen_string_literal: true

# This should be removed. It relies on parsed epub/pdf
# table of contents and is slow. Instead we
# should be using EBookIntervalPresenter
# see HELIO-3277

class RemoveMeEPubIntervalPresenter < ApplicationPresenter
  include Skylight::Helpers
  delegate :title, :level, :cfi, :downloadable?, to: :@interval

  instrument_method
  def initialize(interval)
    @interval = interval
  end
end
