# frozen_string_literal: true

class EPubServiceJob < ApplicationJob
  queue_as :epub_service

  def perform(epub_id) # _later called from EPubService.read
    EPubService.cache_epub(epub_id)
    EPubService.prune_cache
  rescue EPubServiceError => e
    Rails.logger.info(e.message)
  end
end
