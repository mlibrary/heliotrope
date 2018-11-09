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

            it { is_expected.to be_an_instance_of(Sighrax::FeaturedRepresentative) }

            context 'ElectronicPublication' do
              let(:kind) { 'epub' }

              it { is_expected.to be_an_instance_of(Sighrax::ElectronicPublication) }
            end
          end
        end
      end
    end
  end
end
