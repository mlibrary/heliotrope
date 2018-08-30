# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterReportService do
  subject(:counter_report_service) { described_class.new(customer_id, requestor_id) }

  let(:customer_id) { double('customer_id') }
  let(:requestor_id) { double('requestor_id') }
  let(:sushi_service) { double('sushi_service', status: status, members: members, reports: reports) }

  before do
    allow(SushiService).to receive(:new).with(customer_id, 'fulcrum', requestor_id).and_return(sushi_service)
  end

  context 'nil' do
    let(:status) { nil }
    let(:members) { nil }
    let(:reports) { nil }

    it '#active?' do expect(counter_report_service.active?).to be false end
    it '#description' do expect(counter_report_service.description).to eq '' end
    it '#note' do expect(counter_report_service.note).to eq '' end
    it '#alerts' do expect(counter_report_service.alerts).to eq [] end
    it '#members' do expect(counter_report_service.members).to eq [] end
    it '#reports' do expect(counter_report_service.reports).to eq [] end
  end

  context 'nothing' do
    let(:status) { [] }
    let(:members) { [] }
    let(:reports) { [] }

    it '#active?' do expect(counter_report_service.active?).to be false end
    it '#description' do expect(counter_report_service.description).to eq '' end
    it '#note' do expect(counter_report_service.note).to eq '' end
    it '#alerts' do expect(counter_report_service.alerts).to eq [] end
    it '#members' do expect(counter_report_service.members).to be members end
    it '#reports' do expect(counter_report_service.reports).to be reports end
  end

  context 'something' do
    let(:status) { [double('status', service_active: true, description: 'description', note: 'note', alerts: alerts)] }
    let(:alerts) { double('alerts') }
    let(:members) { double('members') }
    let(:reports) { double('reports') }

    it '#active?' do expect(counter_report_service.active?).to be true end
    it '#description' do expect(counter_report_service.description).to eq 'description' end
    it '#note' do expect(counter_report_service.note).to eq 'note' end
    it '#alerts' do expect(counter_report_service.alerts).to be alerts end
    it '#members' do expect(counter_report_service.members).to be members end
    it '#reports' do expect(counter_report_service.reports).to be reports end
  end
end
