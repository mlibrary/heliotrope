# frozen_string_literal: true

class CrossrefPollJob < ApplicationJob
  queue_as :doi
  # We've submitted one or more doi registration requests to Crossref.
  # Now those requests are in their submission queue. It can take
  # some time for requests to get through the queue, so we have to
  # poll it if we want to know if the doi was created successfully.
  #
  # https://support.crossref.org/hc/en-us/articles/217515926
  #
  # This job will call itself(!) until the the registration request(s)
  # has gone through the queue, or if it's run a number of
  # (configurable) times with no results. If that happens the
  # registration request (the entry in the CrossrefSubmissionLog)
  # will be marked abandoned. We can't have this thing just run forever...

  # The creation of multiple doi batches in quick succession from the
  # call to this job from Crossref::Register will mean that there could
  # be overlap in submission polling. We'll probably end up polling more
  # that we need to for some submissions. But I think that's fine.
  # Better than not polling enough, probably.

  def perform(submissions, wait = default_wait_in_seconds, times = 0)
    abandon(submissions) && return if times >= 5

    return if finished?(submissions)

    Rails.logger.info("Running CrossrefPollJob for: #{submissions.map(&:file_name).compact.join("\n")}")

    submissions.each do |submission|
      next if submission.status != "submitted"
      resp = Crossref::CheckSubmission.new(submission.file_name).fetch
      doc = Nokogiri::XML(resp.body)

      submission.status = update_status(submission, doc)
      submission.response_xml = doc.to_xml
      submission.save!
    end
    submissions = submissions.select { |s| s.status == "submitted" }

    return if finished?(submissions)

    sleep(wait)
    times += 1
    CrossrefPollJob.perform_later(submissions, wait, times)
  end

  private

    def update_status(submission, doc)
      status = submission.status
      batch_status = doc.at_css('doi_batch_diagnostic')&.attribute('status')&.value
      if batch_status == "completed"
        status = if doc.at_css('batch_data/failure_count').content != "0"
                   "error"
                 else
                   "success"
                 end
      end
      status
    end

    def finished?(submissions)
      # If no more submissions have a "submitted" status then we're finished
      submissions.map(&:status).none? { |status| status == "submitted" }
    end

    def abandon(submissions)
      # This means we've replayed this job many times and there are still submissions
      # that have "submitted" status. This really shouldn't happen. Crossref's queue
      # is slow, but after a certain amount of time something is probably wrong?
      submissions.each do |submission|
        submission.status = "abandoned"
        submission.save!
      end
    end

    def default_wait_in_seconds
      300
    end
end
