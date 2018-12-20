# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Model, type: :model do
  subject { described_class.send(:new, noid, entity) }

  let(:noid) { double('noid') }
  let(:entity) { double('entity') }

  it { is_expected.to be_a_kind_of(Sighrax::Entity) }
  it { expect(subject.resource_type).to eq :Model }
  it { expect(subject.resource_id).to eq noid }
  it { expect(subject.parent).to be_a_kind_of(Sighrax::NullEntity) }

  describe '#model_type' do
    let(:entity) { { 'has_model_ssim' => ['Model'] } }

    it { expect(subject.send(:model_type)).to eq 'Model' }
  end
end
