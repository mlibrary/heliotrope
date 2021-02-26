# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Entity, type: :model do
  subject(:entity) { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    expect(subject.noid).to eq noid
    expect(subject.send(:data)).to eq data
    expect(subject.resource_id).to eq noid
    expect(subject.resource_token).to eq "#{subject.resource_type}:#{subject.resource_id}"
    expect(subject.resource_type).to eq :Entity
    expect(subject.title).to eq noid
    expect(subject.uri).to eq ActiveFedora::Base.id_to_uri(noid)
    expect(subject.valid?).to be true
  end
end
