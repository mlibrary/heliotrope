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
      is_expected.to be_a CitableLinkPresenter
      is_expected.to be_a EditionPresenter
      is_expected.to be_a FeaturedRepresentatives::MonographPresenter
      is_expected.to be_a OpenUrlPresenter
      is_expected.to be_a SocialShareWidgetPresenter
      is_expected.to be_a TitlePresenter
      is_expected.to be_a TombstonePresenter
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

  describe '#date_created (catalog page citation pub date)' do
    subject { presenter.date_created }

    context 'clean 4 digit year' do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], date_created_tesim: ['1999']) }
      it { is_expected.to eq ['1999'] }
    end

    context "HEB-style 4 digit year with 'circa c', which persists" do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], date_created_tesim: ['c1999']) }
      it { is_expected.to eq ['c1999'] }
    end

    context 'YYYY-MM-DD' do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], date_created_tesim: ['1999-05-06']) }
      it { is_expected.to eq ['1999'] }
    end

    context 'YYYY-MM-DD with some sub-day custom sort number for catalog sort' do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono',
                                          has_model_ssim: ['Monograph'],
                                          date_created_tesim: ['1999-05-06-2']) }
      it { is_expected.to eq ['1999'] }
    end

    context 'a mess' do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono',
                                          has_model_ssim: ['Monograph'],
                                          date_created_tesim: ['this was pubbed on 1999-05-06 LOLZ 123456']) }
      it { is_expected.to eq ['1999'] }
    end
  end

  describe '#authors' do
    before do
      allow(mono_doc).to receive(:creator).and_return(['Cat, Abe'])
      allow(mono_doc).to receive(:contributor).and_return(['Lastname, Thing', 'Feetys, Manny'])
      allow(mono_doc).to receive(:creator_display).and_return(nil)
    end

    describe "creator_display exists, creators/contributors don't" do
      subject { presenter.authors }

      before do
        allow(mono_doc).to receive(:creator_display).and_return('A very elaborate description of editors and authors')
      end

      it { is_expected.to eq 'A very elaborate description of editors and authors' }
    end

    describe "creators/contributors exist, creator_display doesn't" do
      describe 'default (contributors included)' do
        subject { presenter.authors }

        it { is_expected.to eq 'Abe Cat, Thing Lastname and Manny Feetys' }
      end

      describe 'contributors excluded' do
        subject { presenter.authors(contributors: false) }

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

    describe "optional ORCIDs" do
      let(:mono_doc) {
        ::SolrDocument.new(id: 'mono',
                           creator_orcids_ssim: ['https://orcid.org/0000-0002-1825-0097'],
                           contributor_orcids_ssim: ['', 'https://orcid.org/0000-0002-1825-0097'])
      }

      describe 'ORCIDs not included (default)' do
        describe 'default (contributors included)' do
          subject { presenter.authors }

          it { is_expected.to eq 'Abe Cat, Thing Lastname and Manny Feetys' }
        end

        describe 'contributors excluded' do
          subject { presenter.authors(contributors: false) }

          it { is_expected.to eq 'Abe Cat' }
        end
      end

      describe 'ORCIDs included' do
        describe 'default (contributors included)' do
          subject { presenter.authors(orcids: true) }

          it do
            is_expected.to eq 'Abe Cat'\
                              '<sup>'\
                                '<a target="_blank" href="https://orcid.org/0000-0002-1825-0097">' +
                                  ActionController::Base.helpers.image_tag('orcid_16x16.gif', alt: 'ORCID page', width: '16px', height: '16px') +
                                '</a>'\
                              '</sup>'\
                              ', Thing Lastname and Manny Feetys'\
                              '<sup>'\
                                '<a target="_blank" href="https://orcid.org/0000-0002-1825-0097">' +
                                  ActionController::Base.helpers.image_tag('orcid_16x16.gif', alt: 'ORCID page', width: '16px', height: '16px') +
                                '</a>'\
                              '</sup>'
          end
        end

        describe 'contributors excluded' do
          subject { presenter.authors(orcids: true, contributors: false) }

          it do
            is_expected.to eq 'Abe Cat'\
                              '<sup>'\
                                '<a target="_blank" href="https://orcid.org/0000-0002-1825-0097">' +
                                  ActionController::Base.helpers.image_tag('orcid_16x16.gif', alt: 'ORCID page', width: '16px', height: '16px') +
                                  '</a>'\
                              '</sup>'
          end
        end
      end
    end
  end

  describe '#ordered_section_titles' do
    subject { presenter.ordered_section_titles }

    let(:mono_doc) {
      ::SolrDocument.new(id: 'mono',
                         has_model_ssim: ['Monograph'],
                         ordered_member_ids_ssim: ordered_ids)
    }

    let(:cover) { ::SolrDocument.new(id: 'cover',
                                     has_model_ssim: ['FileSet'],
                                     monograph_id_ssim: ['mono']) }
    let(:blue_file) { ::SolrDocument.new(id: 'blue',
                                         has_model_ssim: ['FileSet'],
                                         monograph_id_ssim: ['mono'],
                                         section_title_tesim: ['chapter 2']) }
    let(:green_file) { ::SolrDocument.new(id: 'green',
                                          has_model_ssim: ['FileSet'],
                                          monograph_id_ssim: ['mono'],
                                          section_title_tesim: ['chapter 4']) }

    context 'monograph.ordered_members contains a non-file' do
      let(:non_file) { SolrDocument.new(id: 'NotAFile',
                                        has_model_ssim: ['Monograph'],
                                        monograph_id_ssim: ['mono']) } # It doesn't have section_title_tesim
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
      let(:red_file) { ::SolrDocument.new(id: 'red',
                                          has_model_ssim: ['FileSet'],
                                          monograph_id_ssim: ['mono'],
                                          section_title_tesim: ['chapter 1', 'chapter 3']) }

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
    describe '#featured_representative_docs', :private do
      subject { presenter.featured_representative_docs }

      it 'returns an empty array' do
        expect(subject.count).to eq 0
      end
    end
  end # context 'a monograph without attached members' do

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

    describe '#featured_representative_docs', :private do
      subject { presenter.featured_representative_docs }

      before do
        FeaturedRepresentative.create(work_id: 'mono', file_set_id: 'fs1', kind: 'epub')
        FeaturedRepresentative.create(work_id: 'mono', file_set_id: 'fs2', kind: 'pdf_ebook')
      end

      it 'returns the FeaturedRepresentative docs' do
        expect(subject.count).to eq 2
        expect(subject.map(&:id)).to eq ["fs1", "fs2"]
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
  end

  describe '#bar_number' do
    let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], identifier_tesim: identifier) }

    subject { presenter.bar_number }

    context 'No `bar_number:NNNN` is present in identifier' do
      let(:identifier) { ["http://www.example.com/doi", "999.999.9999"] }

      it { is_expected.to be nil }
    end

    context 'A `bar_number:NNNN` is present in identifier' do
      let(:identifier) { ["http://www.example.com/doi", "999.999.9999", "bar_number:S20156"] }

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
                       creator_tesim: ["Fett, Boba (bounty hunter)\nLane, Lois\nChewbaka"])
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

  describe '#awards' do
    let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], award_tesim: award) }

    subject { presenter.awards }

    context 'No value present in awards' do
      let(:award) { nil }

      it { is_expected.to eq nil }
    end

    context 'A single award' do
      let(:award) { ["2022 |NYT Bestsellers | New York Times"] }

      it 'Formats the award, stripping unwanted spacing' do
        is_expected.to eq '2022 NYT Bestsellers (New York Times)'
      end
    end

    context 'Two awards, one with italics' do
      let(:award) { ["2022|NYT Bestsellers|New York Times", "2022|Book of the Year|American Library Association"] }

      it 'Formats and sorts the awards' do
        is_expected.to eq "2022 Book of the Year (American Library Association)\n2022 NYT Bestsellers (New York Times)"
      end
    end
  end

  describe "#access_level with access_indicators" do
    subject { presenter.access_level(actor_product_ids, allow_read_product_ids) }

    let(:actor_product_ids) { [] }
    let(:allow_read_product_ids) { [] }

    context "unknown (a Monograph with no products indexed)" do
      let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }
      it "returns :unknown" do
        expect(subject.level).to eq :unknown
        expect(subject.show?).to eq false
        expect(subject.icon_sm).to be ""
        expect(subject.icon_lg).to be ""
        expect(subject.text).to be ""
      end
    end

    context "a monograph with an indexed products_lsim field" do
      context "open_access" do
        let(:products) { [-1] } # Open Access product is -1, but we use open_access_tesim to indicate it really. It's odd. Sorry.
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], products_lsim: products, open_access_tesim: ['yes']) }

        it do
          expect(subject.level).to eq :open_access
          expect(subject.show?).to eq true
          expect(subject.icon_sm).to eq ActionController::Base.helpers.image_tag("open-access.svg", width: "16px", height: "16px", alt: "Open Access")
          expect(subject.icon_lg).to eq ActionController::Base.helpers.image_tag("open-access.svg", width: "24px", height: "24px", alt: "Open Access")
          expect(subject.text).to eq ::I18n.t('access_levels.access_level_text.open_access')
        end
      end

      context "purchased" do
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], products_lsim: products) }
        let(:products) { [1] }
        let(:actor_product_ids) { [1] }

        it do
          expect(subject.level).to eq :purchased
          expect(subject.show?).to eq true
          expect(subject.icon_sm).to eq ActionController::Base.helpers.image_tag("green_check.svg", width: "16px", height: "16px", alt: "Purchased")
          expect(subject.icon_lg).to eq ActionController::Base.helpers.image_tag("green_check.svg", width: "24px", height: "24px", alt: "Purchased")
          expect(subject.text).to eq ::I18n.t('access_levels.access_level_text.purchased')
        end
      end

      context "free" do
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], products_lsim: products) }
        let(:products) { [1] }
        let(:allow_read_product_ids) { [1] }

        it do
          expect(subject.level).to eq :free
          expect(subject.show?).to eq true
          expect(subject.icon_sm).to eq ActionController::Base.helpers.image_tag("free.svg", width: "38px", height: "16px", alt: "Free", style: "vertical-align: top")
          expect(subject.icon_lg).to eq ActionController::Base.helpers.image_tag("free.svg", width: "57px", height: "24px", alt: "Free", style: "vertical-align: bottom")
          expect(subject.text).to eq ::I18n.t('access_levels.access_level_text.free')
        end
      end

      context "unrestricted" do
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], products_lsim: products) }
        let(:products) { [0] } # unrestricted is "0", it's a Monograph without a Component

        it do
          expect(subject.level).to eq :unrestricted
          expect(subject.show?).to eq false
          expect(subject.icon_sm).to eq ''
          expect(subject.icon_lg).to eq ''
          expect(subject.text).to eq ''
        end
      end

      context "restricted" do
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], products_lsim: products) }
        let(:products) { [] }

        before do
          FeaturedRepresentative.create(work_id: 'mono', file_set_id: 'epubnoid', kind: 'epub')
        end

        it do
          expect(subject.level).to eq :restricted
          expect(subject.show?).to eq true
          expect(subject.icon_sm).to eq ActionController::Base.helpers.image_tag("lock_locked.svg", width: "16px", height: "16px", alt: "Restricted")
          expect(subject.icon_lg).to eq ActionController::Base.helpers.image_tag("lock_locked.svg", width: "24px", height: "24px", alt: "Restricted")
          expect(subject.text).to eq ::I18n.t('access_levels.access_level_text.restricted') + " " + link_to(::I18n.t('access_levels.access_level_text.restricted_access_options'), Rails.application.routes.url_helpers.monograph_authentication_url(id: "mono"))
        end
      end
    end
  end
end
