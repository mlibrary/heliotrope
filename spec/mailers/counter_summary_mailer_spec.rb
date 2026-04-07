# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CounterSummaryMailer, type: :mailer do
  describe '#missing_file' do
    let(:year) { 2025 }
    let(:month) { 7 }
    let(:mail) { described_class.missing_file(year, month) }

    it 'sends email to fulcrum-dev' do
      expect(mail.to).to eq(['fulcrum-dev@umich.edu'])
    end

    it 'sends from fulcrum-dev' do
      expect(mail.from).to eq(['fulcrum-dev@umich.edu'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq('Missing SIQ Counter Statistics File for July 2025')
    end

    it 'includes the expected filename in the body' do
      expect(mail.body.encoded).to include('fulcrum_metric_totals-2025-07.csv')
    end

    it 'includes the month name in the body' do
      expect(mail.body.encoded).to include('July')
    end

    it 'includes the year in the body' do
      expect(mail.body.encoded).to include('2025')
    end

    it 'includes helpful instructions' do
      expect(mail.body.encoded).to include('AWS credentials')
      expect(mail.body.encoded).to include('S3 bucket')
    end
  end
end
