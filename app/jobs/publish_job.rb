# frozen_string_literal: true

class PublishJob < ApplicationJob
  queue_as :publish

  def perform(curation_concern)
    curation_concern.date_published = [Hyrax::TimeService.time_in_utc]

    # TODO: this is probably not how we publish in the long run
    curation_concern.visibility = 'open'

    curation_concern.save!

    # Publish all the children too
    curation_concern.members.each do |member|
      PublishJob.perform_later(member)
    end
  end
end
