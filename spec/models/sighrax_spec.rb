# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax, type: :model do
  describe '#facotry' do
    subject { described_class.factory(noid) }

    let(:noid) { 'validnoid' }

    it 'null_entity' do
      is_expected.to be_an_instance_of(Sighrax::NullEntity)
      expect(subject.noid).to be noid
    end

    context 'standard error' do
      before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_raise(StandardError) }

      it 'null_entity' do
        is_expected.to be_an_instance_of(Sighrax::NullEntity)
        expect(subject.noid).to be noid
      end
    end

    context 'Entity' do
      let(:entity) { double('entity') }
      let(:model_types) {}

      before do
        allow(ActiveFedora::SolrService).to receive(:query).and_return([entity])
        allow(entity).to receive(:[]).with('has_model_ssim').and_return(model_types)
      end

      it do
        is_expected.to be_an_instance_of(Sighrax::Entity)
        expect(subject.noid).to be noid
        expect(subject.send(:entity)).to be entity
      end

      context 'Model' do
        let(:model_types) { ['Unknown'] }

        it { is_expected.to be_an_instance_of(Sighrax::Model) }

        context 'Monograph' do
          let(:model_types) { ['Monograph'] }

          it { is_expected.to be_an_instance_of(Sighrax::Monograph) }
        end

        context 'Asset' do
          let(:model_types) { ['FileSet'] }
          let(:featured_representatitve) {}

          before { allow(FeaturedRepresentative).to receive(:find_by).with(file_set_id: noid).and_return(featured_representatitve) }

          it { is_expected.to be_an_instance_of(Sighrax::Asset) }

          context 'FeaturedRepresentative' do
            let(:featured_representatitve) { double('featured_representatitve', kind: kind) }
            let(:kind) { 'unknown' }

            it { is_expected.to be_an_instance_of(Sighrax::Asset) }

            context 'ElectronicPublication' do
              let(:kind) { 'epub' }

              it { is_expected.to be_an_instance_of(Sighrax::ElectronicPublication) }
            end
          end
        end
      end
    end
  end

  describe '#hyrax_can?' do
    subject { described_class.hyrax_can?(actor, action, target) }

    let(:actor) { double('actor', is_a?: anonymous) }
    let(:anonymous) { false }
    let(:action) { :read }
    let(:target) { double('target', valid?: valid, noid: 'noid') }
    let(:valid) { true }
    let(:ability) { double('ability') }
    let(:can) { true }

    before do
      allow(Ability).to receive(:new).with(actor).and_return(ability)
      allow(ability).to receive(:can?).with(action.to_s.to_sym, target.noid).and_return(can)
    end

    it { is_expected.to be true }

    context 'anonymous' do
      let(:anonymous) { true }

      it { is_expected.to be false }
    end

    context 'non read action' do
      let(:action) { :write }

      it { is_expected.to be false }
    end

    context 'invalid target' do
      let(:valid) { false }

      it { is_expected.to be false }
    end

    context 'can not' do
      let(:can) { false }

      it { is_expected.to be false }
    end
  end

  describe '#published?' do
    subject { described_class.published?(entity) }

    let(:entity) { double('entity', valid?: true, entity: doc) }
    let(:doc) { { 'suppressed_bsi' => suppressed, 'visibility_ssi' => visibility } }
    let(:suppressed) { true }
    let(:visibility) { 'restricted' }

    it { is_expected.to be false }

    context 'open' do
      let(:visibility) { 'open' }

      it { is_expected.to be false }

      context 'unsuppressed' do
        let(:suppressed) { false }

        it { is_expected.to be true }
      end
    end

    context 'unsuppressed' do
      let(:suppressed) { false }

      it { is_expected.to be false }

      context 'open' do
        let(:visibility) { 'open' }

        it { is_expected.to be true }
      end
    end
  end

  describe '#restricted?' do
    subject { described_class.restricted?(entity) }

    let(:entity) { double('entity', valid?: true, noid: 'noid') }
    let(:component) {}

    before do
      allow(Component).to receive(:find_by).with(noid: entity.noid).and_return(component)
    end

    it { is_expected.to be false }

    context 'present?' do
      let(:component) { double('component') }

      it { is_expected.to be true }
    end
  end
end
