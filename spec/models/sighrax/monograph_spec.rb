# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Monograph, type: :model do
  subject { monograph }

  let(:monograph) { described_class.send(:new, noid, data) }
  let(:noid) { 'validnoid' }
  let(:data) { {} }

  it { is_expected.to be_an_instance_of(described_class) }
  it { is_expected.to be_a_kind_of(Sighrax::Work) }
  it { expect(monograph.resource_type).to eq :Monograph }

  describe '#cover_representative' do
    subject { monograph.cover_representative }

    it { is_expected.to be_an_instance_of(Sighrax::NullEntity) }

    context 'when cover' do
      let(:data) { { 'representative_id_ssim' => ['covernoid'] } }
      let(:cover) { instance_double(Sighrax::Asset, 'cover') }

      before { allow(Sighrax).to receive(:from_noid).with('covernoid').and_return(cover) }

      it { is_expected.to be cover }
    end
  end

  context 'featured representatives' do
    let(:featured_representative) { instance_double(FeaturedRepresentative, 'featured_representative', file_set_id: 'file_set_id') }
    let(:null_entity) { Sighrax::Entity.null_entity }
    let(:asset) { instance_double(Sighrax::Asset, 'asset') }

    before do
      allow(Sighrax).to receive(:from_noid).with(nil).and_return(null_entity)
      allow(Sighrax).to receive(:from_noid).with(featured_representative.file_set_id).and_return(asset)
    end

    describe '#epub_featured_representative' do
      subject { monograph.epub_featured_representative }

      it { is_expected.to be null_entity }

      context 'when epub' do
        before { allow(FeaturedRepresentative).to receive(:find_by).with(work_id: noid, kind: 'epub').and_return(featured_representative) }

        it { is_expected.to be asset }
      end
    end

    describe '#pdf_ebook_featured_representative' do
      subject { monograph.pdf_ebook_featured_representative }

      it { is_expected.to be null_entity }

      context 'when pdf_ebook' do
        before { allow(FeaturedRepresentative).to receive(:find_by).with(work_id: noid, kind: 'pdf_ebook').and_return(featured_representative) }

        it { is_expected.to be asset }
      end
    end
  end

  context 'attributes' do
    let(:monograph) { Sighrax.from_noid(hyrax_monograph.id) }
    let(:hyrax_monograph) { create(:public_monograph) }

    describe '#contributors' do
      subject { monograph.contributors }

      it { is_expected.to be_empty }

      context 'contributor' do
        before do
          hyrax_monograph.contributor = ['Contributor']
          hyrax_monograph.save!
        end

        it { is_expected.to contain_exactly('Contributor') }

        context 'creator' do
          before do
            hyrax_monograph.creator = ['Creator']
            hyrax_monograph.save!
          end

          it { is_expected.to contain_exactly('Creator', 'Contributor') }
        end
      end
    end

    describe '#description' do
      subject { monograph.description }

      before do
        hyrax_monograph.description = ['Description']
        hyrax_monograph.save!
      end

      it { is_expected.to eq('Description') }
    end

    describe '#identifier' do
      subject { monograph.identifier }

      it { is_expected.to eq(HandleNet.url(monograph.noid)) }

      context 'hdl' do
        before do
          hyrax_monograph.hdl = 'Handle'
          hyrax_monograph.save!
        end

        it { is_expected.to eq(HandleNet.url(monograph.noid)) }

        context 'doi' do
          before do
            hyrax_monograph.hdl = 'DOI'
            hyrax_monograph.save!
          end

          it { is_expected.to eq(HandleNet.url(monograph.noid)) }
        end
      end
    end

    describe '#languages' do
      subject { monograph.languages }

      let(:languages) { %w[english french] }

      before do
        hyrax_monograph.language = languages
        hyrax_monograph.save!
      end

      it { is_expected.to contain_exactly(*languages) }
    end

    describe '#modified' do
      subject { monograph.modified }

      let(:modified_date) { Time.parse(Time.now.utc.iso8601) }

      before do
        hyrax_monograph.date_modified = modified_date
        hyrax_monograph.save!
      end

      it { is_expected.to eq(modified_date) }
    end

    describe '#published' do
      subject { monograph.published }

      before do
        hyrax_monograph.date_created = ['2020']
        hyrax_monograph.save!
      end

      it { is_expected.to eq(Date.parse('2020-01-01')) }
    end

    describe '#publisher' do
      subject { monograph.publisher }

      before do
        hyrax_monograph.publisher = ['Publisher']
        hyrax_monograph.save!
      end

      it { is_expected.to eq('Publisher') }
    end

    describe '#series' do
      subject { monograph.series }

      before do
        hyrax_monograph.series = ['Series']
        hyrax_monograph.save!
      end

      it { is_expected.to eq('Series') }
    end

    describe '#subjects' do
      subject { monograph.subjects }

      it { is_expected.to be_empty }

      context 'when singular' do
        before do
          hyrax_monograph.subject = ['A']
          hyrax_monograph.save!
        end

        it { is_expected.to contain_exactly('A') }
      end

      context 'when multiple' do
        before do
          hyrax_monograph.subject = ['A', 'B', 'C']
          hyrax_monograph.save!
        end

        it { is_expected.to contain_exactly('A', 'B', 'C') }
      end
    end
  end
end
