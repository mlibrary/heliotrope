# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Work, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Work }

  describe '#children' do
    it { expect(subject.children).to be_empty }

    context 'children' do
      let(:data) { { 'ordered_member_ids_ssim' => [child.noid] } }
      let(:child) { instance_double(Sighrax::Entity, 'child', noid: 'childnoid') }

      before { allow(Sighrax).to receive(:from_noid).with(child.noid).and_return(child) }

      it { expect(subject.children).not_to be_empty }
      it { expect(subject.children).to contain_exactly(child) }
    end
  end
end
