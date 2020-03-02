# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublisherStatsJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(stats_file) }

  let(:stats_file) { Rails.root.join('tmp', 'publisher_stats.yml').to_s }
  let(:user) { create(:press_editor, press: press) }
  let(:press) { create(:press) }
  let(:monograph) do
    create(:public_monograph, user: user, press: press.subdomain) do |m|
      m.ordered_members << file_set
      m.save!
      file_set.save!
      m
    end
  end
  let(:file_set) { create(:public_file_set) }

  before { monograph }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
    File.delete(stats_file) if File.exist?(stats_file)
  end

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(stats_file)
      .on_queue('default')
  end

  it 'executes perform' do
    expect(File.exist?(stats_file)).to be false
    perform_enqueued_jobs { job }
    expect(File.exist?(stats_file)).to be true
  end
end
