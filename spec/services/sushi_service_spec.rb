# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SushiService do
  let(:sushi_service) { described_class.new(customer_id, platform_id, current_user.email) }
  let(:customer_id) { double('customer_id') }
  let(:institution) { instance_double(Greensub::Institution, 'institution', id: customer_id, name: 'Customer', entity_id: 'entity_id') }
  let(:platform_id) { double('platform_id') }
  let(:press) { instance_double(Press, 'press', name: 'Platform') }
  let(:current_user) { double('current_user', email: 'email') }

  before do
    allow(Greensub::Institution).to receive(:find).with(customer_id).and_return(institution)
    allow(Press).to receive(:find).with(platform_id).and_return(press)
  end

  describe '#status' do
    subject(:status_array) { sushi_service.status }

    it do
      is_expected.to be_an_instance_of(Array)
      expect(status_array.size).to eq 1
      expect(status_array.first).to be_an_instance_of(SwaggerClient::SUSHIServiceStatus)
      expect(status_array.first.description).to eq "COUNTER Usage Reports for #{press.name}."
      expect(status_array.first.service_active).to be true
      expect(status_array.first.registry_url).to eq 'http://test.host/api/sushi'
      expect(status_array.first.note).to eq 'You must be a platform administrator to retrieve reports.'
      expect(status_array.first.alerts).to be_an_instance_of(Array)
      expect(status_array.first.alerts.size).to eq 2
      expect(status_array.first.alerts.first).to be_an_instance_of(SwaggerClient::SUSHIServiceStatusAlerts)
      expect(status_array.first.alerts.first.alert).to eq 'If you can read this ...'
      expect(status_array.first.alerts.last).to be_an_instance_of(SwaggerClient::SUSHIServiceStatusAlerts)
      expect(status_array.first.alerts.last.alert).to eq 'You are too CLOSE!'
    end
  end

  describe '#members' do
    subject(:members) { sushi_service.members }

    it do
      is_expected.to be_an_instance_of(Array)
      expect(members.size).to eq 1
      expect(members.first).to be_an_instance_of(SwaggerClient::SUSHIConsortiumMemberList)
      expect(members.first.customer_id).to be customer_id
      expect(members.first.requestor_id).to eq current_user.email
      expect(members.first.name).to eq institution.name
      expect(members.first.notes).to eq 'entity_id'
      expect(members.first.institution_id).to be_an_instance_of(Array)
      expect(members.first.institution_id).to be_empty
    end
  end

  describe '#reports' do
    subject(:reports) { sushi_service.reports }

    it do
      is_expected.to be_an_instance_of(Array)
      expect(reports.size).to eq 2

      expect(reports.first).to be_an_instance_of(SwaggerClient::SUSHIReportList)
      expect(reports.first.report_name).to eq 'Platform Master Report'
      expect(reports.first.report_id).to eq 'PR'
      expect(reports.first.release).to eq '5'
      expect(reports.first.report_description).to eq 'A customizable report that summarizes activity across a provider’s platforms and allows the user to apply filters and select other configuration options.'
      expect(reports.first.path).to eq 'http://test.host/api/sushi/reports/pr'

      expect(reports.last).to be_an_instance_of(SwaggerClient::SUSHIReportList)
      expect(reports.last.report_name).to eq 'Platform Usage'
      expect(reports.last.report_id).to eq 'PR_P1'
      expect(reports.last.release).to eq '5'
      expect(reports.last.report_description).to eq 'A Standard View of the Platform Master Report offering platform-level usage summarized by metric type.'
      expect(reports.last.path).to eq 'http://test.host/api/sushi/reports/pr_p1'
    end
  end

  describe '#report' do
    subject(:report) { sushi_service.report(id) }

    let(:id) { double('id') }

    it { expect { subject }.to raise_error(StandardError) }

    context 'data reports' do
      let(:id) { 'DR' }

      it do
        is_expected.to be_an_instance_of(SwaggerClient::COUNTERDatabaseReport)
      end
    end

    context 'item reports' do
      let(:id) { 'IR' }

      it do
        is_expected.to be_an_instance_of(SwaggerClient::COUNTERItemReport)
      end
    end

    context 'platform reports' do
      let(:id) { 'PR' }

      it do
        is_expected.to be_an_instance_of(SwaggerClient::COUNTERPlatformReport)
      end
    end

    context 'title reports' do
      let(:id) { 'TR' }

      it do
        is_expected.to be_an_instance_of(SwaggerClient::COUNTERTitleReport)
      end
    end
  end
end
