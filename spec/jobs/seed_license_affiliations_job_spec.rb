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
    let(:individual_license) { create(:full_license, licensee: individual, product: product) }
    let(:institution_license) { create(:read_license, licensee: institution, product: product) }
    let(:individual) { create(:individual) }
    let(:institution) { create(:institution) }
    let(:product) { create(:product) }

    it 'seeds license affiliations' do
      individual_license
      job.perform
      individual_license.reload
      expect(Greensub::LicenseAffiliation.count).to eq 0
      institution_license
      job.perform
      individual_license.reload
      institution_license.reload
      expect(Greensub::LicenseAffiliation.count).to eq 1
      expect(Greensub::LicenseAffiliation.first.license).to eq institution_license
      expect(Greensub::LicenseAffiliation.first.affiliation).to eq 'member'
      job.perform
      individual_license.reload
      institution_license.reload
      expect(Greensub::LicenseAffiliation.count).to eq 1
      expect(Greensub::LicenseAffiliation.first.license).to eq institution_license
      expect(Greensub::LicenseAffiliation.first.affiliation).to eq 'member'
    end
  end
end
