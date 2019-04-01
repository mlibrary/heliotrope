# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax::Model, type: :model do
  subject { described_class.send(:new, uri, jsonld) }

  let(:uri) { 'valid_uri' }
  let(:jsonld) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Fighrax::Node) }
  it { expect(subject.resource_type).to eq :Model }
  it { expect { subject.send(:model) }.to raise_error(StandardError, 'hasModel is blank') }

  context 'with model' do
    let(:jsonld) { { 'hasModel' => 'Model' } }

    it { expect(subject.send(:model)).to eq 'Model' }
  end
end
