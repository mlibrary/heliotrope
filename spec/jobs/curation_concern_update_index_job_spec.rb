# frozen_string_literal: true

require 'rails_helper'

class CurationConcern
  include GlobalID::Identification

  def id; end

  def self.find(_arg); end

  def update_index; end
end

RSpec.describe CurationConcernUpdateIndexJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(curation_concern) }

  let(:curation_concern) { CurationConcern.new }
  let(:id) { 'id' }

  before do
    allow(curation_concern).to receive(:id).and_return(id)
    allow(CurationConcern).to receive(:find).with(id).and_return(curation_concern)
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(curation_concern)
      .on_queue("default")
  end

  it 'executes perform' do
    expect(curation_concern).to receive(:update_index)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
