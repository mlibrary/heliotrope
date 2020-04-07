# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTree, type: :model do
  let(:model_tree) { described_class.from_entity(entity) }
  let(:null_model_tree) { described_class.from_noid(noid) }
  let(:entity) { instance_double(Sighrax::Entity, 'entity', noid: noid) }
  let(:noid) { 'validnoid' }

  describe '#from_noid' do
    subject { described_class.from_noid(noid) }

    it 'initializes' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.noid).to eq noid
      expect(subject.entity).not_to be entity
      expect(subject.entity).to be_an_instance_of(Sighrax::NullEntity)
    end

    context 'entity' do
      before { allow(Sighrax).to receive(:from_noid).with(noid).and_return(entity) }

      it 'initializes' do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.noid).to eq noid
        expect(subject.entity).to be entity
      end
    end
  end

  describe '#from_entity' do
    subject { described_class.from_entity(entity) }

    it 'initializes' do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.noid).to eq noid
      expect(subject.entity).to be entity
    end
  end

  describe '#==' do
    let(:a) { described_class.from_noid('aaaaaaaaa') }
    let(:b) { described_class.from_noid('bbbbbbbbb') }

    it { expect(a == a).to be true }
    it { expect(a == b).to be false }
  end

  context 'delegation' do
    let(:data) { instance_double(ModelTreeData, 'data') }
    let(:kind) { 'kind' }

    before do
      allow(ModelTreeData).to receive(:from_noid).with(noid).and_return(data)
      allow(data).to receive(:kind?)
      allow(data).to receive(:kind)
      allow(data).to receive(:kind=).with(kind)
    end

    it 'delegates kind to data' do
      model_tree.kind?
      expect(data).to have_received(:kind?)
      model_tree.kind
      expect(data).to have_received(:kind)
      model_tree.kind = kind
      expect(data).to have_received(:kind=).with(kind)
    end
  end

  describe '#noid' do
    subject { model_tree.noid }

    it { is_expected.to be noid }
  end

  describe '#entity' do
    subject { model_tree.entity }

    it { is_expected.to be entity }
  end

  describe '#id' do
    subject { model_tree.id }

    it { is_expected.to be noid }
  end

  describe '#null?' do
    it { expect(model_tree.null?).to be false }
    it { expect(null_model_tree.null?).to be true }
  end

  describe '#press' do
    subject { model_tree.press }

    it { is_expected.to be_an_instance_of(NullPress) }

    context 'press' do
      let(:press) { instance_double(Press, 'press') }

      before { allow(Sighrax).to receive(:press).with(entity).and_return(press) }

      it { is_expected.to be press }
    end
  end

  describe '#parent?' do
    subject { model_tree.parent? }

    it { is_expected.to be false }

    context 'parent' do
      let(:edge) { instance_double(ModelTreeEdge, 'edge') }
      let(:parent_entity) { instance_double(Sighrax::Entity, 'parent', noid: parent_noid) }
      let(:parent_noid) { 'parent789' }

      before do
        allow(ModelTreeEdge).to receive(:find_by).with(child_noid: noid).and_return(edge)
        allow(edge).to receive(:parent_noid).and_return(parent_noid)
        allow(Sighrax).to receive(:from_noid).with(parent_noid).and_return(parent_entity)
      end

      it { is_expected.to be true }
    end
  end

  describe '#parent' do
    subject { model_tree.parent }

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.noid).to eq Sighrax::Entity.null_entity.noid }

    context 'parent' do
      let(:edge) { instance_double(ModelTreeEdge, 'edge') }
      let(:parent_entity) { instance_double(Sighrax::Entity, 'parent', noid: parent_noid) }
      let(:parent_noid) { 'parent789' }

      before do
        allow(ModelTreeEdge).to receive(:find_by).with(child_noid: noid).and_return(edge)
        allow(edge).to receive(:parent_noid).and_return(parent_noid)
        allow(Sighrax).to receive(:from_noid).with(parent_noid).and_return(parent_entity)
      end

      it { is_expected.to be_an_instance_of(described_class) }
      it { expect(subject.noid).to be parent_noid }
    end
  end

  describe '#children?' do
    subject { model_tree.children? }

    it { is_expected.to be false }

    context 'children' do
      let(:edge) { instance_double(ModelTreeEdge, 'edge', child_noid: child_noid) }
      let(:child_noid) { 'child6789' }

      before { allow(ModelTreeEdge).to receive(:where).with(parent_noid: noid).and_return([edge]) }

      it { is_expected.to be true }
    end
  end

  describe '#children' do
    subject { model_tree.children }

    it { is_expected.to be_empty }

    context 'children' do
      let(:edge) { instance_double(ModelTreeEdge, 'edge', child_noid: child_noid) }
      let(:child_noid) { 'child6789' }

      before { allow(ModelTreeEdge).to receive(:where).with(parent_noid: noid).and_return([edge]) }

      it { expect(subject.first).to be_an_instance_of(described_class) }
      it { expect(subject.first.noid).to be child_noid }
    end
  end

  describe '#resource_type' do
    subject { model_tree.resource_type }

    let(:resource_type) { :ResourceType }

    before { allow(entity).to receive(:resource_type).and_return(resource_type) }

    it { is_expected.to be resource_type }
  end

  describe '#resource_id' do
    subject { model_tree.resource_id }

    it { is_expected.to eq noid }
  end

  describe '#resource_token' do
    subject { model_tree.resource_token }

    let(:resource_type) { :ResourceType }

    before { allow(entity).to receive(:resource_type).and_return(resource_type) }

    it { is_expected.to eq model_tree.resource_type.to_s + ':' + model_tree.resource_id.to_s }
  end

  describe '#save' do
    let(:service) { instance_double(ModelTreeService, 'service') }
    let(:data) { instance_double(ModelTreeData, 'data') }

    before do
      allow(ModelTreeService).to receive(:new).and_return(service)
      allow(service).to receive(:set_model_tree_data).with(noid, data)
      allow(ModelTreeData).to receive(:from_noid).with(noid).and_return(data)
    end

    it { expect(model_tree.save).to be true }
    it { expect(model_tree.save!).to be true }

    context 'exception' do
      let(:message) { 'ERROR: ModelTree.save raised StandardError' }

      before do
        allow(Rails.logger).to receive(:error).with(message)
        allow(service).to receive(:set_model_tree_data).and_raise(StandardError)
      end

      it do
        expect(model_tree.save).to be false
        expect(Rails.logger).to have_received(:error).with(message)
      end

      it { expect { model_tree.save! }.to raise_error(StandardError) }
    end
  end
end
