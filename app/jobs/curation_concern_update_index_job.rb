# frozen_string_literal: true

class CurationConcernUpdateIndexJob < ApplicationJob
  def perform(curation_concern)
    curation_concern.update_index
  end
end
