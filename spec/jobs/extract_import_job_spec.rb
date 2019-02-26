# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExtractIngestJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(token, base, source, target) }

  let(:token) { 'token' }
  let(:base) { 'base' }
  let(:source) { 'source' }
  let(:target) { 'target' }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }
      .to have_enqueued_job(described_class)
      .with(token, base, source, target)
      .on_queue("default")
  end

  it 'executes perform' do
    perform_enqueued_jobs { job }
  end
end
