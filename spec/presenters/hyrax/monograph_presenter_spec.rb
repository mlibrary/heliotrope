# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::MonographPresenter do
  include ActionView::Helpers::UrlHelper

  let(:presenter) { described_class.new(mono_doc, ability) }
  let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }
  let(:ability) { double('ability') }

  before { allow(ability).to receive(:can?).with(:read, anything).and_return(true) }

  describe '#presenters' do
    subject { described_class.new(nil, nil) }

    it do
      is_expected.to be_a CommonWorkPresenter
      is_expected.to be_a AnalyticsPresenter
      is_expected.to be_a CitableLinkPresenter
      is_expected.to be_a OpenUrlPresenter
      is_expected.to be_a TitlePresenter
      is_expected.to be_a FeaturedRepresentatives::MonographPresenter
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
      subject { presenter.buy_url? }

      before { allow(mono_doc).to receive(:buy_url).and_return([]) }

      it { expect(subject).to be false }
    end

    context 'url' do
      subject { presenter.buy_url? }

      before { allow(mono_doc).to receive(:buy_url).and_return(['url']) }

      it { expect(subject).to be true }
    end
  end

  describe '#buy_url' do
    context 'empty' do
      subject { presenter.buy_url }

      before { allow(mono_doc).to receive(:buy_url).and_return([]) }

      it { expect(subject).to be nil }
    end

    context 'url' do
      subject { presenter.buy_url }

      before { allow(mono_doc).to receive(:buy_url).and_return(['url']) }

      it { expect(subject).to eq 'url' }
    end
  end

  describe '#date_published' do
    subject { presenter.date_published }

    before do
      allow(mono_doc).to receive(:date_published).and_return(['Oct 7th'])
    end

    it { is_expected.to eq ['Oct 7th'] }
  end

  describe '#authors' do
    describe "creator_display exists, creators/contributors don't" do
      subject { presenter.authors }

      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end

      it { is_expected.to eq 'A very elaborate description of editors and authors' }
    end

    before do
      allow(mono_doc).to receive(:creator).and_return(['Cat, Abe'])
      allow(mono_doc).to receive(:contributor).and_return(['Lastname, Thing', 'Feetys, Manny'])
      allow(mono_doc).to receive(:creator_display).and_return(nil)
    end

    describe "creators/contributors exist, creator_display doesn't" do
      describe 'default (contributors included)' do
        subject { presenter.authors }

        it { is_expected.to eq 'Abe Cat, Thing Lastname and Manny Feetys' }
      end

      describe 'contributors excluded' do
        subject { presenter.authors(false) }

        it { is_expected.to eq 'Abe Cat' }
      end
    end

    describe 'creators/contributors exist, as does creator_display' do
      subject { presenter.authors }

      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end

      it { is_expected.to eq 'A very elaborate description of editors and authors' }
    end
  end

  describe '#authors?' do
    subject { presenter.authors? }

    before do
      allow(mono_doc).to receive(:contributor).and_return([])
      allow(mono_doc).to receive(:creator_display).and_return(nil)
    end

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

  context 'a monograph without attached members' do
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
        press_tesim: ['press_tesim'],
        press_name_ssim: ['press_name_ssim'],
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

      it { expect(subject).to contain_exactly('fs1', 'fs2', 'fs3') }

      context 'featured representatives' do
        FeaturedRepresentative::KINDS.each do |kind|
          context kind.to_s do
            let(:featured_representative) { instance_double(FeaturedRepresentative, 'featured_representative', file_set_id: 'fs2', kind: kind) }

            before do
              allow(FeaturedRepresentative).to receive(:where).with(work_id: 'mono').and_return([featured_representative])
              allow(FeaturedRepresentative).to receive(:find_by).with(file_set_id: 'fs2').and_return(featured_representative)
            end

            it { expect(subject).to contain_exactly('fs1', 'fs3') }
          end
        end
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
  end # context 'a monograph with attached members' do

  context 'press' do
    let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], press_tesim: ['subdomain'], press_name_ssim: ['name']) }
    let(:press) { instance_double(Press, 'press', press_url: 'url') }

    before { allow(Press).to receive(:find_by).with(subdomain: mono_doc['press_tesim'].first).and_return(press) }

    describe '#subdomain' do
      subject { presenter.subdomain }

      it { is_expected.to eq('subdomain') }
    end

    describe '#press' do
      subject { presenter.press }

      it { is_expected.to eq('name') }
    end

    describe '#press_obj' do
      subject { presenter.press_obj }

      it { is_expected.to be press }
    end

    describe '#press_url' do
      subject { presenter.press_url }

      it { is_expected.to eq('url') }
    end
  end

  # Dependent upon CitableLinkPresenter
  describe '#heb_dlxs_link' do
    subject { presenter.heb_dlxs_link }

    it { is_expected.to be nil }

    context 'heb' do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], identifier_tesim: [heb_handle]) }
      let(:heb_handle) { 'hTtP://Hdl.Handle.Net/2027/HeB.IdenTifier' }

      it { is_expected.to eq "https://quod.lib.umich.edu/cgi/t/text/text-idx?c=acls;idno=#{presenter.heb_url}" }
    end
  end

  describe '#bar_number' do
    let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], identifier_tesim: identifier) }

    subject { presenter.bar_number }

    context 'No `bar_number: NNNN` is present in identifier' do
      let(:identifier) { ["http://www.example.com/doi", "999.999.9999"] }

      it { is_expected.to be nil }
    end

    context 'A `bar_number: NNNN` is present in identifier' do
      let(:identifier) { ["http://www.example.com/doi", "999.999.9999", "bar_number: S20156"] }

      it { is_expected.to eq 'S20156' }
    end
  end

  describe '#creator' do
    context 'there are values in creator and contributor' do
      subject { presenter.creator }

      before do
        allow(mono_doc).to receive(:creator).and_return(['Man, Rocket', 'Boop, Betty'])
        allow(mono_doc).to receive(:contributor).and_return(['Love, Thomas'])
      end

      # contributors are not used any more in creator (and therefore citations)
      it 'only includes the values in creator' do
        expect(subject).to eq ['Man, Rocket', 'Boop, Betty']
      end
    end

    context 'Solr doc creator values have text following a second comma' do
      subject { presenter.creator }

      before do
        allow(mono_doc).to receive(:creator).and_return(['Man, Rocket, 1888-1968', 'Boop, Betty, some weird stuff'])
        allow(mono_doc).to receive(:contributor).and_return(['Love, Thomas'])
      end

      it 'does not return this extra text' do
        expect(subject).to eq ['Man, Rocket', 'Boop, Betty']
      end
    end
  end

  describe "#creators_with_roles" do
    subject { presenter.creators_with_roles }

    let(:mono_doc) {
      SolrDocument.new(id: 'monograph_id',
                       has_model_ssim: ['Monograph'],
                       importable_creator_ss: "Fett, Boba (bounty hunter); Lane, Lois; Chewbaka")
    }

    it "returns firstname, lastname and role (or the default of 'author')" do
      expect(subject[0].lastname).to eq "Fett"
      expect(subject[0].firstname).to eq "Boba"
      expect(subject[0].role).to eq "bounty hunter"
      expect(subject[1].lastname).to eq "Lane"
      expect(subject[1].firstname).to eq "Lois"
      expect(subject[1].role).to eq "author"
      expect(subject[2].lastname).to eq "Chewbaka"
      expect(subject[2].firstname).to eq ""
      expect(subject[2].role).to eq "author"
    end
  end

  describe '#open_access?' do
    context 'open_access != "yes" (not set)' do
      it { expect(presenter.open_access?).to be false }
    end

    context 'open_access == "yes"' do
      before do
        allow(mono_doc).to receive(:open_access).and_return('YeS')
      end

      it { expect(presenter.open_access?).to be true }
    end
  end

  describe '#funder?' do
    it { expect(presenter.funder?).to be false }

    context 'funder' do
      before { allow(mono_doc).to receive(:funder).and_return('Funder') }

      it { expect(presenter.funder?).to be true }
    end
  end

  describe '#funder_display?' do
    it { expect(presenter.funder_display?).to be false }

    context 'funder_display' do
      before { allow(mono_doc).to receive(:funder_display).and_return('Funder Display') }

      it { expect(presenter.funder_display?).to be true }
    end
  end
end
