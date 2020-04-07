# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTreeData, type: :model do
  subject { model_tree_data }

  let(:model_tree_data) { described_class.from_hash(data) }
  let(:data) { { 'kind' => kind } }
  let(:kind) { 'kind' }

  context 'factories' do
    describe '#from_noid' do
      subject(:instance) { described_class.from_noid(noid) }

      let(:noid) { 'validnoid' }

      it 'initializes' do
        expect(instance).to be_an_instance_of(described_class)
        expect(instance.kind).to eq nil
      end

      context 'vertex' do
        let(:vertex) { instance_double(ModelTreeVertex, 'vertex', data: { data: data }.to_json) }

        before { allow(ModelTreeVertex).to receive(:find_by).with(noid: noid).and_return(vertex) }

        it 'initializes' do
          expect(instance).to be_an_instance_of(described_class)
          expect(instance.kind).to eq kind
        end
      end
    end

    describe '#from_json' do
      subject(:instance) { described_class.from_json(json) }

      let(:json) { { data: data }.to_json }

      it 'initializes' do
        expect(instance).to be_an_instance_of(described_class)
        expect(instance.kind).to eq kind
      end
    end

    describe '#from_hash' do
      subject(:instance) { described_class.from_hash(data) }

      it 'initializes' do
        expect(instance).to be_an_instance_of(described_class)
        expect(instance.kind).to eq kind
      end
    end
  end

  describe '#==' do
    let(:a) { described_class.from_hash({ 'a' => 'a' }) }
    let(:b) { described_class.from_hash({ 'a' => 'b' }) }

    it { expect(a == a).to be true }
    it { expect(a == b).to be false }
  end

  describe '#kind?' do
    subject { model_tree_data.kind? }

    it { is_expected.to be true }

    context 'kind: nil' do
      let(:kind) { nil }

      it { is_expected.to be false }
    end
  end

  describe '#kind' do
    subject { model_tree_data.kind }

    it { is_expected.to eq kind }

    context 'kind: nil' do
      let(:kind) { nil }

      it { is_expected.to eq kind }
    end
  end

  describe '#kind=' do
    let(:other_kind) { 'other_kind' }

    it do
      expect(model_tree_data.kind).to eq kind
      expect(model_tree_data.kind = other_kind).to eq other_kind
      expect(model_tree_data.kind).to eq other_kind
    end
  end
end
