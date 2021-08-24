# frozen_string_literal: true

class FixityJob < ApplicationJob
  queue_as :fixity

  def perform
    ActiveRecord::Base.clear_active_connections! # https://github.com/resque/resque#rails-4x

    file_set_ids = ActiveFedora::SolrService.query("+has_model_ssim:FileSet",
                                                  fl: ['id'],
                                                  sort: 'date_modified_dtsi desc',
                                                  rows: FileSet.all.count).map(&:id)

    # Temporarily set a limit on the number of new file_sets to be checked so we can
    # stagger the initial fixity checking over a number of days instead of doing them all
    # on one day. After all files have the initial check, remove the limit

    limit = 3600 # todo: remove
    current = 0 # todo: remove
    file_set_ids.each do |id|
      next if ChecksumAuditLog.where(file_set_id: id).where("updated_at > ?", 30.days.ago).present? # todo: remove
      next if current >= limit # todo: remove
      Hyrax::FileSetFixityCheckService.new(id, async_jobs: false, max_days_between_fixity_checks: 30, latest_version_only: true).fixity_check
      current += 1 # todo: remove
    end
  end
end
