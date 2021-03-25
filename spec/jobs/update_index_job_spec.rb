# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateIndexJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(noid) }

  let(:noid) { 'validnoid' }
  let(:entity) { double('entity') }

  before do
    allow(Sighrax).to receive(:from_noid).with(noid).and_return(entity)
    allow(entity).to receive(:is_a?).and_return(false)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(noid)
      .on_queue("default")
  end

  it 'executes perform' do
    perform_enqueued_jobs { job }
    expect(Sighrax).to have_received(:from_noid).with(noid)
  end

  context 'Monograph' do
    let(:monograph) { double('monograph') }

    before do
      allow(entity).to receive(:is_a?).with(Sighrax::Monograph).and_return(true)
      allow(Monograph).to receive(:find).with(noid).and_return(monograph)
      allow(monograph).to receive(:update_index)
    end

    it 'executes update_index' do
      perform_enqueued_jobs { job }
      expect(monograph).to have_received(:update_index)
    end
  end

  context 'Resource' do
    let(:asset) { double('asset') }

    before do
      allow(entity).to receive(:is_a?).with(Sighrax::Resource).and_return(true)
      allow(FileSet).to receive(:find).with(noid).and_return(asset)
      allow(asset).to receive(:update_index)
    end

    it 'executes update_index' do
      perform_enqueued_jobs { job }
      expect(asset).to have_received(:update_index)
    end
  end
end
