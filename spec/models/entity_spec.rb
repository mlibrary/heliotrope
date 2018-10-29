# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Entity, type: :model do
  describe 'null entity' do
    subject { described_class.null_object }

    it 'is invalid' do
      expect(subject).to be_invalid
      expect(subject).to be_a_kind_of(described_class)
      expect(subject.null_object?).to be true
      expect(subject.type).to eq 'null_type'
      expect(subject.id).to eq 'null_id'
      expect(subject.identifier).to eq 'null_type:null_id'
      expect(subject.name).to eq 'EntityNullObject'
    end
  end

  describe 'entities' do
    describe 'nil:nil entity' do
      subject { described_class.new('identifier', 'name', type: nil, id: nil) }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).not_to be_empty
        expect(subject).to be_a_instance_of(described_class)
        expect(subject.null_object?).to be false
        expect(subject.type).to be nil
        expect(subject.id).to be nil
        expect(subject.identifier).to eq 'identifier'
        expect(subject.name).to eq 'name'
      end
    end

    describe 'type invalid entity' do
      subject { described_class.new('invalid', 'type', type: :type, id: 0) }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).not_to be_empty
        expect(subject).to be_a_instance_of(described_class)
        expect(subject.null_object?).to be false
        expect(subject.type).to eq 'type'
        expect(subject.id).to eq '0'
        expect(subject.identifier).to eq 'invalid'
        expect(subject.name).to eq 'type'
      end
    end

    describe 'any:any entity' do
      subject { described_class.new('wild', 'card') }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject).to be_a_instance_of(described_class)
        expect(subject.null_object?).to be false
        expect(subject.type).to eq 'any'
        expect(subject.id).to eq 'any'
        expect(subject.identifier).to eq 'wild'
        expect(subject.name).to eq 'card'
      end
    end

    describe 'email entity' do
      subject { described_class.new(1, 'Universtiy of Michigan', type: :email, id: 'wolverine@umich.edu') }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject).to be_a_instance_of(described_class)
        expect(subject.null_object?).to be false
        expect(subject.type).to eq 'email'
        expect(subject.id).to eq 'wolverine@umich.edu'
        expect(subject.identifier).to eq '1'
        expect(subject.name).to eq 'Universtiy of Michigan'
      end
    end

    describe 'epub entity' do
      subject { described_class.new('mobydick.epub', 'Moby Dick', type: :epub, id: :validnoid) }

      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
        expect(subject).to be_a_instance_of(described_class)
        expect(subject.null_object?).to be false
        expect(subject.type).to eq 'epub'
        expect(subject.id).to eq 'validnoid'
        expect(subject.identifier).to eq 'mobydick.epub'
        expect(subject.name).to eq 'Moby Dick'
      end
    end
  end
end
