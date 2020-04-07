# frozen_string_literal: true

require 'rails_helper'

describe ModelTreePresenter do
  subject(:presenter) { described_class.new(current_user, model_tree) }

  let(:current_user) { double("current_user") }
  let(:model_tree) { instance_double(ModelTree, 'model_tree') }

  context 'delegation' do
    before do
      allow(model_tree).to receive(:id)
      allow(model_tree).to receive(:noid)
      allow(model_tree).to receive(:entity)
      allow(model_tree).to receive(:press)
      allow(model_tree).to receive(:kind?)
      allow(model_tree).to receive(:kind)
      allow(model_tree).to receive(:parent?)
      allow(model_tree).to receive(:children?)
    end

    it 'delegates to model_tree' do
      presenter.id
      expect(model_tree).to have_received(:id)
      presenter.noid
      expect(model_tree).to have_received(:noid)
      presenter.entity
      expect(model_tree).to have_received(:entity)
      presenter.press
      expect(model_tree).to have_received(:press)
      presenter.kind?
      expect(model_tree).to have_received(:kind?)
      presenter.kind
      expect(model_tree).to have_received(:kind)
      presenter.parent?
      expect(model_tree).to have_received(:parent?)
      presenter.children?
      expect(model_tree).to have_received(:children?)
    end
  end

  describe '#display_name' do
    subject { presenter.display_name }

    let(:entity) { instance_double(Sighrax::Entity, 'entity') }
    let(:title) { double('title') }

    before do
      allow(model_tree).to receive(:entity).and_return(entity)
      allow(entity).to receive(:title).and_return(title)
    end

    it { is_expected.to be title }
  end

  describe '#parent' do
    subject { presenter.parent }

    let(:parent) { instance_double(ModelTree, 'parent') }

    before { allow(model_tree).to receive(:parent).and_return(parent) }

    it { expect(subject).to be_an_instance_of(described_class) }
    it { expect(subject.model_tree).to be parent }
  end

  describe '#children' do
    subject { presenter.children }

    let(:children) { [child] }
    let(:child) { instance_double(ModelTree, 'child') }

    before { allow(model_tree).to receive(:children).and_return(children) }

    it { expect(subject.count).to eq(1) }
    it { expect(subject.first).to be_an_instance_of(described_class) }
    it { expect(subject.first.model_tree).to be child }
  end

  describe '#kind_display' do
    subject { presenter.kind_display }

    let(:kind) { double('kind') }
    let(:kind_display) { double('kind_display') }

    before do
      allow(model_tree).to receive(:kind).and_return(kind)
      allow(I18n).to receive(:t).with("model_tree_data.kind.#{kind}").and_return(kind_display)
    end

    it { is_expected.to be kind_display }
  end

  describe '#kind_options?' do
    subject { presenter.kind_options? }

    it { is_expected.to be true }
  end

  describe '#kind_options' do
    subject { presenter.kind_options }

    let(:kind_options) { ModelTreeData::KINDS.map { |k| [I18n.t("model_tree_data.kind.#{k}"), k] } }

    it { is_expected.to contain_exactly(*kind_options) }
  end

  context 'Model Tree Service' do
    let(:noid) { 'validnoid' }
    let(:service) { instance_double(ModelTreeService, 'service') }
    let(:noids) { [] }

    before do
      allow(model_tree).to receive(:noid).and_return(noid)
      allow(ModelTreeService).to receive(:new).and_return(service)
    end

    context 'parent options' do
      before { allow(service).to receive(:select_parent_options).with(noid).and_return(noids) }

      describe '#parent_options?' do
        subject { presenter.parent_options? }

        it { is_expected.to be false }

        context 'options' do
          let(:noids) { [noid] }

          it { is_expected.to be true }
        end
      end

      describe '#parent_options' do
        subject { presenter.parent_options }

        it { is_expected.to be_empty }

        context 'options' do
          let(:noids) { [noid] }

          it { is_expected.to contain_exactly([Sighrax.from_noid(noid).title, noid]) }
        end
      end
    end

    context 'child options' do
      before { allow(service).to receive(:select_child_options).with(noid).and_return(noids) }

      describe '#child_options?' do
        subject { presenter.child_options? }

        it { is_expected.to be false }

        context 'options' do
          let(:noids) { [noid] }

          it { is_expected.to be true }
        end
      end

      describe '#child_options' do
        subject { presenter.child_options }

        it { is_expected.to be_empty }

        context 'options' do
          let(:noids) { [noid] }

          it { is_expected.to contain_exactly([Sighrax.from_noid(noid).title, noid]) }
        end
      end
    end
  end
end
