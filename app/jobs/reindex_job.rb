# frozen_string_literal: true

class ReindexJob < ApplicationJob
  def perform(target)
    case target
    when 'everything'
      ActiveFedora::Base.reindex_everything
    when 'monographs'
      Monograph.all.each do |monograph|
        UpdateIndexJob.perform_later(monograph.id)
      end
    when 'file_sets'
      FileSet.all.each do |file_set|
        UpdateIndexJob.perform_later(file_set.id)
      end
    else
      noids = [target].flatten
      noids.each do |noid|
        UpdateIndexJob.perform_later(noid)
      end
    end
  end
end
