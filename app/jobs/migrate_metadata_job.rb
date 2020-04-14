# frozen_string_literal: true

class MigrateMetadataJob < ApplicationJob
  def perform(kind, target = nil)
    noids = if target.present?
              Array(target).flatten
            else
              FileSet.all.map(&:id)
            end

    noids.each do |noid|
      case kind
      when 'transcript'
        migrate_transcript_to_captions(noid)
      end
    end

    true
  end

  def migrate_transcript_to_captions(noid)
    file_set = FileSet.find(noid)
    return false unless file_set.video?
    return false if file_set.transcript.blank?
    return false if file_set.closed_captions.present?

    file_set.closed_captions = Array(Array(file_set.transcript).first).flatten
    file_set.save!

    true
  rescue StandardError => e
    Rails.logger.error("ERROR: MigrateMetadataJob#migrate_transcript_to_captions(#{noid}) raised #{e}")
    false
  end
end
