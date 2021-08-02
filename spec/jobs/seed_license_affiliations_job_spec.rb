# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeedLicenseAffiliationsJob, type: :job do
  include ActiveJob::TestHelper

  describe 'job queue' do
    subject(:job) { described_class.perform_later }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe 'job' do
    let(:job) { described_class.new }
    let(:license_1) { create(:full_license, licensee: licensee, product: product) }
    let(:license_2) { create(:read_license, licensee: licensee, product: product) }
    let(:licensee) { create(:individual) }
    let(:product) { create(:product) }

    it 'seeds license affiliations' do
      license_1
      job.perform
      license_1.reload
      expect(Greensub::LicenseAffiliation.count).to eq 1
      expect(Greensub::LicenseAffiliation.first.license).to eq license_1
      expect(Greensub::LicenseAffiliation.first.affiliation).to eq 'member'
      license_2
      job.perform
      license_1.reload
      license_2.reload
      expect(Greensub::LicenseAffiliation.count).to eq 2
      expect(Greensub::LicenseAffiliation.first.license).to eq license_1
      expect(Greensub::LicenseAffiliation.first.affiliation).to eq 'member'
      expect(Greensub::LicenseAffiliation.last.license).to eq license_2
      expect(Greensub::LicenseAffiliation.last.affiliation).to eq 'member'
    end
  end
end
