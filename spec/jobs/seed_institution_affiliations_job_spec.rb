# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SeedInstitutionAffiliationsJob, type: :job do
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
    let(:institution_1) { create(:institution) }
    let(:institution_2) { create(:institution) }

    it 'seeds institution affiliations' do
      institution_1
      job.perform
      institution_1.reload
      expect(Greensub::InstitutionAffiliation.count).to eq 1
      expect(Greensub::InstitutionAffiliation.first.institution).to eq institution_1
      expect(Greensub::InstitutionAffiliation.first.dlps_institution_id.to_s).to eq institution_1.identifier
      expect(Greensub::InstitutionAffiliation.first.affiliation).to eq 'member'
      institution_2
      job.perform
      institution_1.reload
      institution_2.reload
      expect(Greensub::InstitutionAffiliation.count).to eq 2
      expect(Greensub::InstitutionAffiliation.first.institution).to eq institution_1
      expect(Greensub::InstitutionAffiliation.first.dlps_institution_id.to_s).to eq institution_1.identifier
      expect(Greensub::InstitutionAffiliation.first.affiliation).to eq 'member'
      expect(Greensub::InstitutionAffiliation.last.institution).to eq institution_2
      expect(Greensub::InstitutionAffiliation.last.dlps_institution_id.to_s).to eq institution_2.identifier
      expect(Greensub::InstitutionAffiliation.last.affiliation).to eq 'member'
    end
  end
end
