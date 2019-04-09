# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Model, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Entity) }
  it { expect(subject.resource_type).to eq :Model }
  it { expect(subject.send(:model_type)).to be_nil }
  it { expect(subject.presenter).to be_an_instance_of(Sighrax::NullEntity) }

  describe '#model_type' do
    let(:data) { { 'has_model_ssim' => ['Model'] } }

    it { expect(subject.send(:model_type)).to eq 'Model' }
  end
end
