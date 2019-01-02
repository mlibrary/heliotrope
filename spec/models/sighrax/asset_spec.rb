# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Asset, type: :model do
  subject { described_class.send(:new, noid, entity) }

  let(:noid) { double('noid') }
  let(:entity) { {} }

  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Asset }
  it { expect(subject.resource_id).to eq noid }
  it { expect(subject.parent).to be_a_kind_of(Sighrax::NullEntity) }

  describe '#parent' do
    let(:entity) { { 'monograph_id_ssim' => [noid] } }
    let(:parent) { double('parent') }

    before { allow(Sighrax).to receive(:factory).with(noid).and_return(parent) }

    it { expect(subject.parent).to be parent }
  end
end
