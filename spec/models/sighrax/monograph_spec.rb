# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Monograph, type: :model do
  subject { described_class.send(:new, noid, entity) }

  let(:noid) { 'validnoid' }
  let(:entity) { {} }

  it { is_expected.to be_a_kind_of(Sighrax::Model) }
  it { expect(subject.resource_type).to eq :Monograph }
  it { expect(subject.resource_id).to eq noid }
  it { expect(subject.open_access?).to be false }
  it { expect(subject.epub_featured_representative).to be_a(Sighrax::NullEntity) }

  describe '#open_access?' do
    let(:entity) { { 'open_access_tesim' => ['YeS'] } }

    it { expect(subject.open_access?).to be true }
  end

  describe '#epub_featured_representative' do
    let(:epub_featured_representative) { double('epub_featured_representative', file_set_id: 'file_set_id') }
    let(:electronic_publication) { double('electronic_publication') }

    before do
      allow(FeaturedRepresentative).to receive(:find_by).with(monograph_id: noid, kind: 'epub').and_return(epub_featured_representative)
      allow(Sighrax).to receive(:factory).with(epub_featured_representative.file_set_id).and_return(electronic_publication)
    end

    it { expect(subject.epub_featured_representative).to be electronic_publication }
  end
end
