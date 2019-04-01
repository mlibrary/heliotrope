# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax::Node, type: :model do
  context 'null node' do
    subject { described_class.null_node }

    it { is_expected.to be_an_instance_of(Fighrax::NullNode) }
    it { expect(subject.uri).to eq ActiveFedora::Base.id_to_uri('null_uri') }
    it { expect(subject.jsonld).to eq({}) }
    it { expect(subject.valid?).to be false }
    it { expect(subject.resource_type).to eq :NullNode }
    it { expect(subject.resource_id).to eq 'null_uri' }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of(Fighrax::NullNode) }
    it { expect(subject.title).to eq subject.uri }
  end

  context 'node' do
    subject(:node) { described_class.send(:new, uri, jsonld) }

    let(:uri) { 'valid_uri' }
    let(:jsonld) { {} }

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.uri).to eq uri }
    it { expect(subject.jsonld).to eq jsonld }
    it { expect(subject.valid?).to be true }
    it { expect(subject.resource_type).to eq :Node }
    it { expect(subject.resource_id).to eq ActiveFedora::Base.uri_to_id(uri) }
    it { expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}" }
    it { expect(subject.parent).to be_an_instance_of(Fighrax::NullNode) }
    it { expect(subject.title).to eq subject.uri }

    context 'with title' do
      let(:jsonld) { { 'title' => 'Title' } }

      it { expect(subject.title).to eq 'Title' }
    end
  end
end
