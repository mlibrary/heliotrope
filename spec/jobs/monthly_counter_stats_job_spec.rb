# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyCounterStatsJob, type: :job do
  describe '#perform' do
    let(:press) { create(:press, subdomain: 'blue', name: 'The Blue Press') }
    let(:email) { 'test@example.com' }
    let(:year) { 2024 }
    let(:month) { 1 }
    let(:mailer) { double('mailer', deliver_now: true) }

    before do
      allow(CounterSummaryMailer).to receive(:send_report).and_return(mailer)
    end

    it 'calls the CounterSummaryMailer with the correct params' do
      described_class.perform_now(press_id: press.id, year: year, month: month, email: email)
      expect(CounterSummaryMailer).to have_received(:send_report).with(
        hash_including(
          email: email,
          press: press.name,
          year: year,
          month: month
        )
      )
    end
  end
end
