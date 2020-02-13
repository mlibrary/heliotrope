# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Monograph, type: :model do
  subject { described_class.send(:new, noid, data) }

  let(:noid) { 'validnoid' }
  let(:data) { {} }
  let(:electronic_publication) { double('electronic_publication') }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Work) }
  it { expect(subject.resource_type).to eq :Monograph }
  it { expect(subject.epub_featured_representative).to be_an_instance_of(Sighrax::NullEntity) }

  describe '#epub_featured_representative' do
    let(:epub_featured_representative) { double('epub_featured_representative', file_set_id: 'file_set_id') }

    before do
      allow(FeaturedRepresentative).to receive(:find_by).with(work_id: noid, kind: 'epub').and_return(epub_featured_representative)
      allow(Sighrax).to receive(:from_noid).with(epub_featured_representative.file_set_id).and_return(electronic_publication)
    end

    it { expect(subject.epub_featured_representative).to be electronic_publication }
  end

  describe '#pdf_ebook_featured_representative' do
    let(:pdf_ebook_featured_representative) { double('pdf_ebook_featured_representative', file_set_id: 'file_set_id') }

    before do
      allow(FeaturedRepresentative).to receive(:find_by).with(work_id: noid, kind: 'pdf_ebook').and_return(pdf_ebook_featured_representative)
      allow(Sighrax).to receive(:from_noid).with(pdf_ebook_featured_representative.file_set_id).and_return(electronic_publication)
    end

    it { expect(subject.pdf_ebook_featured_representative).to be electronic_publication }
  end
end
