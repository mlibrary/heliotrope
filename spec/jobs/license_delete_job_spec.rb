# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LicenseDeleteJob, type: :job do
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
    let(:blank) { create(:license, type: '') }
    let(:license) { create(:license) }
    let(:read_license) { create(:read_license) }
    let(:full_license) { create(:full_license) }
    let(:individual) { create(:individual) }
    let(:product) { create(:product) }
    let(:blank_grant) { create(:individual_license_grant, agent_id: individual.id, credential_id: blank.id, resource_id: product.id) }
    let(:license_grant) { create(:individual_license_grant, agent_id: individual.id, credential_id: license.id, resource_id: product.id) }

    before do
      clear_grants_table
    end

    it 'deletes blank and license' do
      blank
      license
      read_license
      full_license
      expect(Greensub::License.count).to eq 4
      job.perform
      expect(Greensub::License.count).to eq 2
      expect { Greensub::License.find(blank.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect { Greensub::License.find(license.id) }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'deletes blank and license and grants' do
      blank
      license
      read_license
      full_license
      blank_grant
      license_grant
      expect(Greensub::License.count).to eq 4
      expect(grants_table_count).to eq 2
      job.perform
      expect(Greensub::License.count).to eq 2
      expect { Greensub::License.find(blank.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect { Greensub::License.find(license.id) }.to raise_exception ActiveRecord::RecordNotFound
      expect(grants_table_count).to eq 0
    end
  end
end
