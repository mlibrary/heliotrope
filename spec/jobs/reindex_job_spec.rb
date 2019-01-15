# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(target) }

  let(:target) { 'validnoid' }

  before do
    allow(UpdateIndexJob).to receive(:perform_later)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(target)
      .on_queue("default")
  end

  it 'executes perform' do
    perform_enqueued_jobs { job }
    expect(UpdateIndexJob).to have_received(:perform_later).with(target)
  end

  context 'noids' do
    let(:target) { %w[validnoid ValidNoid] }

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(UpdateIndexJob).to have_received(:perform_later).with('validnoid')
      expect(UpdateIndexJob).to have_received(:perform_later).with('ValidNoid')
    end
  end

  context 'everything' do
    let(:target) { 'everything' }

    before do
      allow(ActiveFedora::Base).to receive(:reindex_everything)
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(ActiveFedora::Base).to have_received(:reindex_everything)
    end
  end

  context 'monographs' do
    let(:target) { 'monographs' }
    let(:monographs) { [monograph1, monograph2] }
    let(:monograph1) { double('monograph1', id: '1') }
    let(:monograph2) { double('monograph2', id: '2') }

    before do
      allow(Monograph).to receive(:all).and_return(monographs)
      allow(UpdateIndexJob).to receive(:perform_later).with(monograph1.id)
      allow(UpdateIndexJob).to receive(:perform_later).with(monograph2.id)
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(UpdateIndexJob).to have_received(:perform_later).with(monograph1.id)
      expect(UpdateIndexJob).to have_received(:perform_later).with(monograph2.id)
    end
  end

  context 'file_sets' do
    let(:target) { 'file_sets' }
    let(:file_sets) { [file_set1, file_set2] }
    let(:file_set1) { double('file_set1', id: '1') }
    let(:file_set2) { double('file_set2', id: '2') }

    before do
      allow(FileSet).to receive(:all).and_return(file_sets)
      allow(UpdateIndexJob).to receive(:perform_later).with(file_set1.id)
      allow(UpdateIndexJob).to receive(:perform_later).with(file_set2.id)
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
      expect(UpdateIndexJob).to have_received(:perform_later).with(file_set1.id)
      expect(UpdateIndexJob).to have_received(:perform_later).with(file_set2.id)
    end
  end
end
