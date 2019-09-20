# frozen_string_literal: true

class CrossrefPollJob < ApplicationJob
  queue_as :doi
  # We've submitted one or more doi registration requests to Crossref.
  # Now those requests are in their submission queue. It can take
  # some time for requests to get through the queue, so we have to
  # poll it if we want to know if the doi was created successfully.
  #
  # https://support.crossref.org/hc/en-us/articles/217515926

  def perform
    submissions = CrossrefSubmissionLog.where(status: "submitted")

    submissions.each do |submission|
      resp = Crossref::CheckSubmission.new(submission.file_name).fetch
      doc = Nokogiri::XML(resp.body)

      submission.status = update_status(submission, doc)
      submission.response_xml = doc.to_xml
      submission.save!
    end
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
end
