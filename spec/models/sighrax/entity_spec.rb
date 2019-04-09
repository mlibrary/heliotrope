# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Entity, type: :model do
  context 'null entity' do
    subject { described_class.null_entity }

    it { is_expected.to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.noid).to eq 'null_noid' }
    it { expect(subject.send(:data)).to eq({}) }
    it { expect(subject.valid?).to be false }
    it { expect(subject.uri).to eq ActiveFedora::Base.id_to_uri('null_noid') }
    it { expect(subject.resource_type).to eq :NullEntity }
    it { expect(subject.resource_id).to eq 'null_noid' }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.title).to eq 'null_noid' }
  end

  context 'entity' do
    subject(:entity) { described_class.send(:new, noid, data) }

    let(:noid) { 'validnoid' }
    let(:data) { {} }

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.noid).to eq noid }
    it { expect(subject.send(:data)).to eq data }
    it { expect(subject.valid?).to be true }
    it { expect(subject.uri).to eq ActiveFedora::Base.id_to_uri(noid) }
    it { expect(subject.resource_type).to eq :Entity }
    it { expect(subject.resource_id).to eq noid }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity) }
    it { expect(subject.title).to eq noid }
  end
end
