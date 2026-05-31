require 'spec_helper'

RSpec.describe Hydra::PCDM::AncestorChecker do
  context '.former_is_ancestor_of_latter?' do
    subject { described_class.former_is_ancestor_of_latter?(potential_ancestor, record) }
    let(:record) { instance_double(Hydra::PCDM::Object) }
    let(:potential_ancestor) { nil }

    context 'when the potential_ancestor is the record itself' do
      let(:potential_ancestor) { record }
      it { is_expected.to eq(true) }
    end

    context 'when the potential_ancestor has no members' do
      let(:potential_ancestor) { instance_double(Hydra::PCDM::Object, members: []) }
      it { is_expected.to eq(false) }
    end

    context 'when the potential_ancestor includes the given record' do
      let(:potential_ancestor) { instance_double(Hydra::PCDM::Object, members: [record]) }
      it { is_expected.to eq(true) }
    end

    context 'when the potential_ancestor includes a descendant that includes the given record' do
      let(:descendant) { instance_double(Hydra::PCDM::Object, members: [record]) }
      let(:potential_ancestor) { instance_double(Hydra::PCDM::Object, members: [descendant]) }
      it { is_expected.to eq(true) }
    end

    context 'when the potential_ancestor only includes descendants that do not include the given record' do
      let(:descendant) { instance_double(Hydra::PCDM::Object, members: [:another]) }
      let(:potential_ancestor) { instance_double(Hydra::PCDM::Object, members: [descendant]) }
      it { is_expected.to eq(false) }
    end
  end
end
