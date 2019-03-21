# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax do
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
      let(:data) { double('data') }
      let(:model_types) {}

      before do
        allow(ActiveFedora::SolrService).to receive(:query).and_return([data])
        allow(data).to receive(:[]).with('has_model_ssim').and_return(model_types)
      end

      it do
        is_expected.to be_an_instance_of(Sighrax::Entity)
        expect(subject.noid).to be noid
        # expect(subject.send(:data)).to be data
        expect(subject.data).to be data
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

            context 'Mobipocket' do
              let(:kind) { 'mobi' }

              it { is_expected.to be_an_instance_of(Sighrax::Mobipocket) }
            end

            context 'PortableDocumentFormat' do
              let(:kind) { 'pdf_ebook' }

              it { is_expected.to be_an_instance_of(Sighrax::PortableDocumentFormat) }
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
    let(:action) { :action }
    let(:target) { double('target', valid?: valid, noid: 'noid') }
    let(:valid) { true }
    let(:ability) { double('ability') }
    let(:can) { true }

    before do
      allow(Ability).to receive(:new).with(actor).and_return(ability)
      allow(ability).to receive(:can?).with(action, target.noid).and_return(can)
    end

    context 'user can' do
      it { is_expected.to be true }

      context 'anonymous' do
        let(:anonymous) { true }

        it { is_expected.to be false }
      end

      context 'invalid action' do
        let(:action) { 'action' }

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
  end

  describe '#deposited?' do
    subject { described_class.deposited?(entity) }

    let(:entity) { double('entity', valid?: true, data: data) }
    let(:data) { {} }

    it { is_expected.to be true }

    context "'suppressed_bsi' => false" do
      let(:data) { { 'suppressed_bsi' => false } }

      it { is_expected.to be true }
    end

    context "'suppressed_bsi' => true" do
      let(:data) { { 'suppressed_bsi' => true } }

      it { is_expected.to be false }
    end
  end

  describe '#open_access?' do
    subject { described_class.open_access?(entity) }

    let(:entity) { double('entity', valid?: true, data: data) }
    let(:data) { {} }

    it { is_expected.to be false }

    context "'open_access_tesim' => ''" do
      let(:data) { { 'open_access_tesim' => [''] } }

      it { is_expected.to be false }
    end

    context "'open_access_tesim' => 'yes'" do
      let(:data) { { 'open_access_tesim' => ['yes'] } }

      it { is_expected.to be true }
    end
  end

  describe '#published?' do
    subject { described_class.published?(entity) }

    let(:entity) { double('entity', valid?: true, data: data) }
    let(:data) { {} }

    it { is_expected.to be false }

    context "'visibility_ssi' => 'restricted'" do
      let(:data) { { 'visibility_ssi' => 'restricted' } }

      it { is_expected.to be false }
    end

    context "'visibility_ssi' => 'open'" do
      let(:data) { { 'visibility_ssi' => 'open' } }

      it { is_expected.to be true }

      context "'suppressed_bsi' => true" do
        let(:data) { { 'suppressed_bsi' => true, 'visibility_ssi' => 'open' } }

        it { is_expected.to be false }
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
