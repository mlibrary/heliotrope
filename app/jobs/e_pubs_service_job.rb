# frozen_string_literal: true

class EPubsServiceJob < ApplicationJob
  queue_as :epubs_service

  def perform(epub_id) # _later called from EPubsService.open
    EPubsService.cache_epub(epub_id)
    EPubsIndexJob.perform_later(epub_id)
    EPubsService.prune_cache
  rescue EPubsServiceError => e
    Rails.logger.info(e.message)
  end
end
