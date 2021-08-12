# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LicenseToGrantJob, type: :job do
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
    let(:license_1) { create(:full_license, licensee: individual, product: product_1) }
    let(:license_2) { create(:read_license, licensee: institution, product: product_1) }
    let(:license_3) { create(:read_license, licensee: individual, product: product_2) }
    let(:license_4) { create(:full_license, licensee: institution, product: product_2) }
    let(:individual) { create(:individual) }
    let(:institution) { create(:institution) }
    let(:product_1) { create(:product) }
    let(:product_2) { create(:product) }

    before { clear_grants_table }

    it 'creates grants for licenses' do
      license_1
      expect(grants_table_count).to eq 0
      job.perform
      expect(grants_table_count).to eq 1
      expect(grants_table_last.credential_id.to_i).to eq license_1.id

      license_2
      expect(grants_table_count).to eq 1
      job.perform
      expect(grants_table_count).to eq 2
      expect(grants_table_last.credential_id.to_i).to eq license_2.id

      license_3
      expect(grants_table_count).to eq 2
      job.perform
      expect(grants_table_count).to eq 3
      expect(grants_table_last.credential_id.to_i).to eq license_3.id

      license_4
      expect(grants_table_count).to eq 3
      job.perform
      expect(grants_table_count).to eq 4
      expect(grants_table_last.credential_id.to_i).to eq license_4.id
    end
  end
end
