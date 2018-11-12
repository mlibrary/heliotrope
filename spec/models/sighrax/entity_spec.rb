# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Entity, type: :model do
  subject { described_class.send(:new, noid, entity) }

  let(:noid) { double('noid') }
  let(:entity) { double('entity') }

  it { expect(subject.resource_type).to eq :Entity }
  it { expect(subject.resource_id).to eq noid }

  context 'valid noid' do
    let(:noid) { 'validnoid' }
    let(:entity) { {} }

    before { allow(ActiveFedora::SolrService).to receive(:query).with("{!terms f=id}#{noid}", rows: 1).and_return([entity]) }

    it { is_expected.to be_an_instance_of(Sighrax::Entity) }

    context 'entity' do
      let(:entity) { { "solr" => "document" } }

      it 'is expected' do
        is_expected.to be_an_instance_of(described_class)
        expect(subject.valid?).to be true
        expect(subject.noid).to eq noid
        expect(subject.title).to eq noid
      end
    end

    context 'model' do
      let(:entity) do
        {
          'has_model_ssim' => ['Unknown'],
          'title_tesim' => ['Unknown Entity']
        }
      end

      it 'is expected' do
        is_expected.to be_an_instance_of(described_class)
        expect(subject.valid?).to be true
        expect(subject.noid).to eq noid
        expect(subject.title).to eq 'Unknown Entity'
      end
    end
  end
end
