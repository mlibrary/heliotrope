# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Entity, type: :model do
  describe 'null entity' do
    subject { described_class.null_object }

    it 'is invalid' do
      expect(subject).to be_invalid
      expect(subject).to be_a_kind_of(described_class)
      expect(subject.null_object?).to be true
      expect(subject.id).to eq "null:null"
    end
  end

  describe 'entities' do
    subject { described_class.new(type: type, identifier: identifier) }

    describe 'invalid entity' do
      let(:type) { '' }
      let(:identifier) { '' }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).not_to be_empty
        expect(subject.null_object?).not_to be true
        expect(subject.id).to eq "#{type}:#{identifier}"
      end
    end

    describe 'user entity' do
      let(:type) { :email.to_s }
      let(:identifier) { user.email }
      let(:user) { build(:user) }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject.null_object?).not_to be true
        expect(subject.id).to eq "#{type}:#{identifier}"
      end
    end

    describe 'epub entity' do
      let(:type) { :epub.to_s }
      let(:identifier) { :noid.to_s }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject.null_object?).not_to be true
        expect(subject.id).to eq "#{type}:#{identifier}"
      end
    end
  end
end
