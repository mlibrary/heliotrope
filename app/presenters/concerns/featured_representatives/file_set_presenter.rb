# frozen_string_literal: true

module FeaturedRepresentatives
  module FileSetPresenter
    extend ActiveSupport::Concern

    def featured_representative
      FeaturedRepresentative.where(monograph_id: monograph_id, file_set_id: id).first
    end

    def featured_representative?
      featured_representative ? true : false
    end

    def epub_locked?
      return false unless epub?
      entity = Entity.new(type: :epub, identifier: id)
      !Subscription.find_by(subscriber: entity.id, publication: entity.id).nil?
    end

    def epub_unlocked?
      !epub_locked?
    end

    def epub?
      # ['application/epub+zip'].include? mime_type
      featured_representative&.kind == 'epub'
    end

    def webgl?
      # ['application/zip', 'application/octet-stream'].include?(mime_type) && File.extname(original_name) == ".unity"
      featured_representative&.kind == 'webgl'
    end
  end
end
