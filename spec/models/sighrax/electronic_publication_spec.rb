# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::ElectronicPublication, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { double('noid') }
  let(:data) { double('data') }

  it { is_expected.to be_a_kind_of(Sighrax::Asset) }
  it { expect(subject.resource_type).to eq :ElectronicPublication }
  it { expect(subject.resource_id).to eq noid }
end
