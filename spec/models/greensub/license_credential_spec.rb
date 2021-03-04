# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub::LicenseCredential, type: :model do
  subject { described_class.new(id) }

  let(:id) { 'id' }

  it { is_expected.to be_kind_of Checkpoint::Credential }
  it { expect(subject.id).to eq id }
  it { expect(subject.name).to eq id }
  it { expect(subject.type).to eq described_class::TYPE }
  it { expect(described_class::TYPE).to eq 'License' }
end
