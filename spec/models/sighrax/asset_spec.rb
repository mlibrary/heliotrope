# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Asset, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { double('noid') }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Asset }
  it { expect(subject.parent).to be_an_instance_of(Sighrax::NullEntity) }
  it { expect(subject.presenter).to be_an_instance_of(Sighrax::NullEntity) }

  describe '#parent' do
    let(:data) { { 'monograph_id_ssim' => [noid] } }
    let(:parent) { double('parent') }

    before { allow(Sighrax).to receive(:factory).with(noid).and_return(parent) }

    it { expect(subject.parent).to be parent }
  end

  describe '#presenter' do
    let(:file_set) { create(:file_set) }
    let(:noid) { file_set.id }

    it { expect(subject.presenter).to be_an_instance_of(Hyrax::FileSetPresenter) }
  end
end
