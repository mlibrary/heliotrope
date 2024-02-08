# frozen_string_literal: true

# This should be removed. It relies on parsed epub/pdf
# table of contents and is slow. Instead we
# should be using EBookIntervalPresenter
# see HELIO-3277

class RemoveMeEPubIntervalPresenter < ApplicationPresenter
  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # include Skylight::Helpers
  delegate :title, :level, :cfi, :downloadable?, to: :@interval

  # commented out during Hyrax 4 upgrade (see HELIO-4582)
  # TODO: put Skylight back in action post-upgrade (see HELIO-4589)
  # instrument_method
  def initialize(interval)
    @interval = interval
  end
end
