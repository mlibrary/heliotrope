# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax::AccessControl, type: :model do
  subject { described_class.send(:new, uri, jsonld) }

  let(:uri) { 'valid_uri' }
  let(:jsonld) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Fighrax::Model) }
  it { expect(subject.resource_type).to eq :AccessControl }
end
