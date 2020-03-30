# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PDFIntervalRecord, type: :model do
  subject { described_class.new(args) }

  let(:args) { { noid: 'validnoid', data: '[]' } }

  it 'is valid' do
    expect(subject).to be_valid
    expect(subject.errors.messages).to be_empty
    expect(subject.save!).to be true
    expect(subject.destroy!).to be subject
  end

  context 'no noid' do
    subject { described_class.new(args) }

    let(:args) { { noid: nil, data: '[]' } }

    it 'is invalid' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).not_to be_empty
      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'no data' do
    subject { described_class.new(args) }

    let(:args) { { noid: 'validnoid', data: nil } }

    it 'is invalid' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).not_to be_empty
      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
