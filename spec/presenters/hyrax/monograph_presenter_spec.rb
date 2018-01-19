# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::MonographPresenter do
  include ActionView::Helpers::UrlHelper

  before { Press.destroy_all }
  let(:press) { create(:press, subdomain: 'michigan') }

  let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }
  let(:ability) { double('ability') }
  let(:presenter) { described_class.new(mono_doc, ability) }

  describe '#presenters' do
    subject { described_class.new(nil, nil) }
    it do
      is_expected.to be_a CCAnalyticsPresenter
      is_expected.to be_a ISBNPresenter
      is_expected.to be_a OpenUrlPresenter
      is_expected.to be_a TitlePresenter
    end
  end

  describe '#assets?' do
    subject { presenter.assets? }

    let(:mono_doc) {
      ::SolrDocument.new(id: 'mono',
                         has_model_ssim: ['Monograph'],
                         # representative_id has a rather different Solr name!
                         hasRelatedMediaFragment_ssim: cover.id,
                         ordered_member_ids_ssim: ordered_ids)
    }

    let(:cover) { ::SolrDocument.new(id: 'cover', has_model_ssim: ['FileSet']) }
    let(:blue_file) { ::SolrDocument.new(id: 'blue', has_model_ssim: ['FileSet']) }
    let(:green_file) { ::SolrDocument.new(id: 'green', has_model_ssim: ['FileSet']) }

    context 'has assets' do
      let(:ordered_ids) { [cover.id, blue_file.id, green_file.id] }

      before do
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([mono_doc.to_h, cover.to_h, blue_file.to_h, green_file.to_h])
        ActiveFedora::SolrService.commit
      end
      it { is_expected.to be true }
    end
    context 'does not have assets' do
      let(:ordered_ids) { [cover.id] }

      before do
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([mono_doc.to_h, cover.to_h])
        ActiveFedora::SolrService.commit
      end
      it { is_expected.to be false }
    end
  end

  describe '#monograph_coins_title?' do
    subject { presenter.monograph_coins_title? }
    context 'undef' do
      before { presenter.instance_eval('undef :monograph_coins_title') }
      it { is_expected.to be false }
    end
    context 'def' do
      context 'blank' do
        before { allow(presenter).to receive(:monograph_coins_title).and_return('') }
        it { is_expected.to be false }
      end
      context 'present' do
        before { allow(presenter).to receive(:monograph_coins_title).and_return('MONOGRAPH-COINS-TITLE') }
        it { is_expected.to be true }
      end
    end
  end

  describe '#buy_url?' do
    context 'empty' do
      before { allow(mono_doc).to receive(:buy_url).and_return([]) }
      subject { presenter.buy_url? }
      it { expect(subject).to be false }
    end
    context 'url' do
      before { allow(mono_doc).to receive(:buy_url).and_return(['url']) }
      subject { presenter.buy_url? }
      it { expect(subject).to be true }
    end
  end

  describe '#buy_url' do
    context 'empty' do
      before { allow(mono_doc).to receive(:buy_url).and_return([]) }
      subject { presenter.buy_url }
      it { expect(subject).to be nil }
    end
    context 'url' do
      before { allow(mono_doc).to receive(:buy_url).and_return(['url']) }
      subject { presenter.buy_url }
      it { expect(subject).to eq 'url' }
    end
  end

  describe '#date_published' do
    before do
      allow(mono_doc).to receive(:date_published).and_return(['Oct 7th'])
    end
    subject { presenter.date_published }
    it { is_expected.to eq ['Oct 7th'] }
  end

  describe '#editors' do
    before do
      allow(mono_doc).to receive(:primary_editor_given_name).and_return('Abe')
      allow(mono_doc).to receive(:primary_editor_family_name).and_return('Cat')
      allow(mono_doc).to receive(:editor).and_return(['Thing Lastname', 'Manny Feetys'])
    end
    subject { presenter.editors }
    it { is_expected.to eq "Abe Cat, Thing Lastname, and Manny Feetys" }
  end

  describe '#editors?' do
    describe "no editors or creator_display" do
      before do
        allow(mono_doc).to receive(:primary_editor_given_name).and_return(nil)
        allow(mono_doc).to receive(:primary_editor_family_name).and_return(nil)
        allow(mono_doc).to receive(:editor).and_return([])
      end
      subject { presenter.editors? }
      it { is_expected.to eq false }
    end
    before do
      allow(mono_doc).to receive(:primary_editor_given_name).and_return('Abe')
      allow(mono_doc).to receive(:primary_editor_family_name).and_return('Cat')
      allow(mono_doc).to receive(:editor).and_return(['Thing Lastname', 'Manny Feetys'])
    end
    describe "editors, no creator_display" do
      subject { presenter.editors? }
      it { is_expected.to eq true }
    end
    describe "creator_display overrides editors when both are present" do
      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end
      subject { presenter.editors? }
      it { is_expected.to eq false }
    end
  end

  describe '#authors' do
    describe "creator_display exists, creators/contributors don't" do
      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end
      subject { presenter.authors }
      it { is_expected.to eq 'A very elaborate description of editors and authors' }
    end
    before do
      allow(mono_doc).to receive(:creator_given_name).and_return('Abe')
      allow(mono_doc).to receive(:creator_family_name).and_return('Cat')
      allow(mono_doc).to receive(:contributor).and_return(['Thing Lastname', 'Manny Feetys'])
      allow(mono_doc).to receive(:creator_display).and_return(nil)
    end
    describe "creators/contributors exist, creator_display doesn't" do
      subject { presenter.authors }
      it { is_expected.to eq 'Abe Cat, Thing Lastname, and Manny Feetys' }
    end
    describe 'creators/contributors exist, as does creator_display' do
      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end
      subject { presenter.authors }
      it { is_expected.to eq 'A very elaborate description of editors and authors' }
    end
  end

  describe '#authors?' do
    before do
      allow(mono_doc).to receive(:creator_given_name).and_return(nil)
      allow(mono_doc).to receive(:creator_family_name).and_return(nil)
      allow(mono_doc).to receive(:contributor).and_return([])
      allow(mono_doc).to receive(:creator_display).and_return(nil)
    end
    subject { presenter.authors? }
    it { is_expected.to eq false }
  end

  describe '#ordered_section_titles' do
    subject { presenter.ordered_section_titles }

    let(:mono_doc) {
      ::SolrDocument.new(id: 'mono',
                         has_model_ssim: ['Monograph'],
                         ordered_member_ids_ssim: ordered_ids)
    }

    let(:cover) { ::SolrDocument.new(id: 'cover', has_model_ssim: ['FileSet']) }
    let(:blue_file) { ::SolrDocument.new(id: 'blue', has_model_ssim: ['FileSet'], section_title_tesim: ['chapter 2']) }
    let(:green_file) { ::SolrDocument.new(id: 'green', has_model_ssim: ['FileSet'], section_title_tesim: ['chapter 4']) }

    context 'monograph.ordered_members contains a non-file' do
      let(:non_file) { SolrDocument.new(id: 'NotAFile', has_model_ssim: ['Monograph']) } # It doesn't have section_title_tesim
      let(:ordered_ids) { [cover.id, blue_file.id, non_file.id, green_file.id] }

      before do
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([mono_doc.to_h, cover.to_h, blue_file.to_h, non_file.to_h, green_file.to_h])
        ActiveFedora::SolrService.commit
      end

      it 'returns the list of chapter titles' do
        expect(subject).to eq ["chapter 2", "chapter 4"]
      end
    end

    context 'a fileset that belongs to more than 1 chapter' do
      let(:red_file) { ::SolrDocument.new(id: 'red', has_model_ssim: ['FileSet'], section_title_tesim: ['chapter 1', 'chapter 3']) }

      let(:ordered_ids) {
        # red_file appears in both chapter 1 and chapter 3
        [cover.id, red_file.id, blue_file.id, red_file.id, green_file.id]
      }

      before do
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([mono_doc.to_h, cover.to_h, red_file.to_h, blue_file.to_h, green_file.to_h])
        ActiveFedora::SolrService.commit
      end

      # Notice that these chapter titles are out of order.
      # That's because the ordered_section_titles method
      # assumes that each FileSet has only 1 section_title.
      # Since red_file has 2 values for section_title, the
      # assumption is broken, so the order isn't guaranteed.
      it 'has all the chapters in the list' do
        expect(subject).to eq ["chapter 1", "chapter 3", "chapter 2", "chapter 4"]
      end
    end
  end

  context 'a monograph with no attached members' do
    describe '#ordered_file_sets_ids', :private do
      subject { presenter.ordered_file_sets_ids }
      it 'returns an empty array' do
        expect(subject.count).to eq 0
      end
    end

    describe '#previous_file_sets_id?' do
      subject { presenter.previous_file_sets_id? 0 }
      it 'returns false' do
        expect(subject).to eq false
      end
    end

    describe '#previous_file_sets_id' do
      subject { presenter.previous_file_sets_id 0 }
      it 'returns nil' do
        expect(subject).to eq nil
      end
    end

    describe '#next_file_sets_id?' do
      subject { presenter.next_file_sets_id? 0 }
      it 'returns false' do
        expect(subject).to eq false
      end
    end

    describe '#next_file_sets_id' do
      subject { presenter.next_file_sets_id 0 }
      it 'returns nil' do
        expect(subject).to eq nil
      end
    end

    describe '#epub?' do
      subject { presenter.epub? }
      it { expect(subject).to be false }
    end

    describe '#epub' do
      subject { presenter.epub }
      it { expect(subject).to be nil }
    end
  end # context 'a monograph with no attached members' do

  context 'a monograph with attached members' do
    # the cover FileSet won't be included in the ordered_file_sets_ids
    let(:cover_fileset_doc) { ::SolrDocument.new(id: 'cover', has_model_ssim: ['FileSet']) }
    let(:fs1_doc) { ::SolrDocument.new(id: 'fs1', has_model_ssim: ['FileSet']) }
    let(:fs2_doc) { ::SolrDocument.new(id: 'fs2', has_model_ssim: ['FileSet']) }
    let(:fs3_doc) { ::SolrDocument.new(id: 'fs3', has_model_ssim: ['FileSet']) }

    let(:expected_id_count) { 3 }

    let(:mono_doc) do
      ::SolrDocument.new(
        id: 'mono',
        has_model_ssim: ['Monograph'],
        # representative_id has a rather different Solr name!
        hasRelatedMediaFragment_ssim: cover_fileset_doc.id,
        ordered_member_ids_ssim: [cover_fileset_doc.id, fs1_doc.id, fs2_doc.id, fs3_doc.id]
      )
    end

    before do
      # SolrService.add takes hashes not docs!
      ActiveFedora::SolrService.add([mono_doc.to_h, cover_fileset_doc.to_h, fs1_doc.to_h, fs2_doc.to_h, fs3_doc.to_h])
      ActiveFedora::SolrService.commit
    end

    describe '#ordered_file_sets_ids' do
      subject { presenter.ordered_file_sets_ids }

      it 'returns an array of expected size' do
        expect(subject.count).to eq expected_id_count
      end

      it 'the first element of the array is as expected' do
        expect(subject.first).to eq 'fs1'
      end

      it 'the last element of the array is as expected' do
        expect(subject.last).to eq 'fs3'
      end
    end

    context 'the first (non-representative) file' do
      describe '#previous_file_sets_id?' do
        subject { presenter.previous_file_sets_id? fs1_doc.id }
        it { is_expected.to be false }
      end

      describe '#previous_file_sets_id' do
        subject { presenter.previous_file_sets_id fs1_doc.id }
        it { is_expected.to eq nil }
      end

      describe '#next_file_sets_id?' do
        subject { presenter.next_file_sets_id? fs1_doc.id }
        it { is_expected.to eq true }
      end

      describe '#next_file_sets_id' do
        subject { presenter.next_file_sets_id fs1_doc.id }
        it { is_expected.to eq fs2_doc.id }
      end
    end

    context 'the 2nd file in the list' do
      describe '#previous_file_sets_id?' do
        subject { presenter.previous_file_sets_id? fs2_doc.id }
        it { is_expected.to eq true }
      end

      describe '#previous_file_sets_id' do
        subject { presenter.previous_file_sets_id fs2_doc.id }
        it { is_expected.to eq fs1_doc.id }
      end

      describe '#next_file_sets_id?' do
        subject { presenter.next_file_sets_id? fs2_doc.id }
        it { is_expected.to eq true }
      end

      describe '#next_file_sets_id' do
        subject { presenter.next_file_sets_id fs2_doc.id }
        it { is_expected.to eq fs3_doc.id }
      end
    end

    context 'the last file in the list' do
      describe '#previous_file_sets_id?' do
        subject { presenter.previous_file_sets_id? fs3_doc.id }
        it { is_expected.to eq true }
      end

      describe '#previous_file_sets_id' do
        subject { presenter.previous_file_sets_id fs3_doc.id }
        it { is_expected.to eq fs2_doc.id }
      end

      describe '#next_file_sets_id?' do
        subject { presenter.next_file_sets_id? fs3_doc.id }
        it { is_expected.to eq false }
      end

      describe '#next_file_sets_id' do
        subject { presenter.next_file_sets_id fs3_doc.id }
        it { is_expected.to eq nil }
      end
    end

    describe "#representative_presenter" do
      subject { presenter.representative_presenter }

      it "returns a FileSetPresenter" do
        expect(subject.class).to eq Hyrax::FileSetPresenter
      end
    end

    describe '#epub?' do
      subject { presenter.epub? }
      it { expect(subject).to be false }
    end

    describe '#epub' do
      subject { presenter.epub }
      it { expect(subject).to be nil }
    end

    context 'featured_representatives' do
      let!(:fr1) { create(:featured_representative, monograph_id: presenter.id,
                                                    file_set_id: fs2_doc.id,
                                                    kind: 'epub') }
      let!(:fr2) { create(:featured_representative, monograph_id: presenter.id,
                                                    file_set_id: fs3_doc.id,
                                                    kind: 'webgl') }
      after do
        FeaturedRepresentative.destroy_all
      end

      describe '#featured_representatives' do
        subject { presenter.featured_representatives }
        it { expect(subject.count).to be 2 }
      end

      describe '#epub?' do
        subject { presenter.epub? }
        it { expect(subject).to be true }
      end

      describe '#epub' do
        subject { presenter.epub }
        it { expect(subject.id).to eq fs2_doc.id }
      end

      describe '#epub_id' do
        subject { presenter.epub_id }
        it { expect(subject).to eq fs2_doc.id }
      end

      describe '#webgl?' do
        subject { presenter.webgl? }
        it { expect(subject).to be true }
      end

      describe '#webgl' do
        subject { presenter.webgl }
        it { expect(subject.id).to eq fs3_doc.id }
      end

      describe '#webgl_id' do
        subject { presenter.webgl_id }
        it { expect(subject).to eq fs3_doc.id }
      end
    end
  end # context 'a monograph with attached members' do

  describe "#citable_link" do
    context "with an explicit handle" do
      let(:mono_doc) { SolrDocument.new(id: 'monograph_id', has_model_ssim: ['Monograph'], hdl_ssim: ['a.handle']) }

      it "has that explicit handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.a.handle"
      end
    end

    context "with no explicit handle" do
      let(:mono_doc) { SolrDocument.new(id: 'monograph_id', has_model_ssim: ['FileSet']) }

      it "has the default NOID based handle" do
        expect(presenter.citable_link).to eq "http://hdl.handle.net/2027/fulcrum.monograph_id"
      end
    end
  end
end
