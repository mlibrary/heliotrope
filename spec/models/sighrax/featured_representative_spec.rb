# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::FeaturedRepresentative, type: :model do
  subject { described_class.send(:new, noid, entity) }

  let(:noid) { double('noid') }
  let(:entity) { double('entity') }

  it { is_expected.to be_a_kind_of(Sighrax::Asset) }
  it { expect(subject.resource_type).to eq :FeaturedRepresentative }
  it { expect(subject.resource_id).to eq noid }

  describe '#featured_representative' do
    let(:featured_representative) { double('featured_representative') }

    before { allow(FeaturedRepresentative).to receive(:find_by).with(file_set_id: noid).and_return(featured_representative) }

    it { expect(subject.send(:featured_representative)).to be featured_representative }
  end
end
