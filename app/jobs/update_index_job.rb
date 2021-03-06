# frozen_string_literal: true

require_dependency 'sighrax'

class UpdateIndexJob < ApplicationJob
  def perform(noid)
    entity = Sighrax.from_noid(noid)
    if entity.is_a?(Sighrax::Monograph)
      Monograph.find(noid)&.update_index
    elsif entity.is_a?(Sighrax::Resource)
      FileSet.find(noid)&.update_index
    end
  end
end
