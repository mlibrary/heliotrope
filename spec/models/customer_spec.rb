# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'null customer' do
    subject { described_class.null_object }

    it 'is invalid' do
      expect(subject).to be_invalid
      expect(subject).to be_a_kind_of(described_class)
      expect(subject.null_object?).to be true
      expect(subject.id).to be nil
      expect(subject.save).to be false
      expect { subject.save! }.to raise_error(ActiveRecord::RecordNotSaved)
    end
  end

  describe 'id' do
    subject { described_class.new(id) }

    context 'nil' do
      let(:id) { nil }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).not_to be_empty
        expect(subject.null_object?).to be false
        expect(subject.id).to be nil
        expect(subject.save).to be false
        expect { subject.save! }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end

    context 'blank' do
      let(:id) { '' }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).not_to be_empty
        expect(subject.null_object?).to be false
        expect(subject.id).to eq ''
        expect(subject.save).to be false
        expect { subject.save! }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end

    context 'present' do
      let(:id) { 'id' }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject.null_object?).to be false
        expect(subject.id).to eq 'id'
        expect(subject.save).to be false
        expect { subject.save! }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end
  end
end
