# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTreeVertex, type: :model do
  context 'Factory Bot' do
    subject(:vertex) { create(:model_tree_vertex) }

    it do
      expect(ValidationService.valid_noid?(vertex.noid)).to be true
    end
  end

  context 'Validation' do
    subject { described_class.new(noid: noid) }

    context 'blank noid' do
      let(:noid) { nil }

      it 'validates presence' do
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Noid can't be blank", "Noid must be 9 alphanumeric characters")
      end
    end

    context 'invalid noid' do
      let(:noid) { 'invalidnoid' }

      it 'validates presence' do
        expect(subject.valid?).to be false
        expect(subject.errors).to contain_exactly("Noid must be 9 alphanumeric characters")
      end
    end

    context 'valid noid' do
      let(:noid) { 'validnoid' }

      it 'validates presence' do
        expect(subject.valid?).to be true
        expect(subject.errors).to be_empty
      end
    end
  end
end
