# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Work, type: :model do
  subject { work }

  let(:work) { described_class.send(:new, noid, data) }
  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Work }

  describe '#children' do
    subject { work.children }

    it { is_expected.to be_empty }

    context 'children' do
      let(:data) { { 'ordered_member_ids_ssim' => [child.noid] } }
      let(:child) { instance_double(Sighrax::Entity, 'child', noid: 'childnoid') }

      before { allow(Sighrax).to receive(:from_noid).with(child.noid).and_return(child) }

      it { is_expected.to contain_exactly(child) }
    end
  end

  describe '#children_noids' do
    subject { work.children_noids }

    it { is_expected.to be_empty }

    context 'children' do
      let(:data) { { 'ordered_member_ids_ssim' => [child.noid] } }
      let(:child) { instance_double(Sighrax::Entity, 'child', noid: 'childnoid') }

      before { allow(Sighrax).to receive(:from_noid).with(child.noid).and_return(child) }

      it { is_expected.to contain_exactly(child.noid) }
    end
  end
end
