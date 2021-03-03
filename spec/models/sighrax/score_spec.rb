# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Score, type: :model do
  subject { Sighrax.from_noid(score.id) }

  let(:score) { create(:public_score) }

  it 'has expected values' do
    is_expected.to be_an_instance_of described_class
    is_expected.to be_a_kind_of Sighrax::Work
    expect(subject.resource_type).to eq :Score
  end
end
