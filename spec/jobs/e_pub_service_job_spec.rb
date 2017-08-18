# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubServiceJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(epub_id) }

  let(:epub_id) { "epub_id" }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(epub_id)
      .on_queue("epub_service")
  end

  it 'executes perform' do
    allow(EPubIndexJob).to receive(:perform_later).with(epub_id)
    expect(EPubService).to receive(:cache_epub).with(epub_id).ordered
    expect(EPubIndexJob).to receive(:perform_later).with(epub_id).ordered
    expect(EPubService).to receive(:prune_cache).with(no_args).ordered
    perform_enqueued_jobs { job }
  end

  it 'logs EPubServiceError' do
    allow(EPubService).to receive(:cache_epub).and_raise(EPubServiceError, "message")
    expect(Rails.logger).to receive(:info).with("message")
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
