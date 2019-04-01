# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax::RebuildFedoraContainsJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later }

  let(:monograph) { create(:public_monograph) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class).on_queue('default')
  end

  it 'perform when fedora empty' do
    perform_enqueued_jobs { job }
    expect(FedoraContain.count.zero?).to be true
  end

  it 'perform when fedora non-empty' do
    monograph
    perform_enqueued_jobs { job }
    expect(FedoraContain.count.positive?).to be true

    sighrax_monograph = Sighrax.factory(monograph.id)
    fighrax_monograph = Fighrax.factory(monograph.uri)

    expect(sighrax_monograph.noid).to eq(fighrax_monograph.noid)
    expect(sighrax_monograph.uri).to eq(fighrax_monograph.uri)
  end
end
