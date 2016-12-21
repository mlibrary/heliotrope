require 'rails_helper'

describe OpenUrlPresenter do
  let(:press) { build(:press, subdomain: 'merp', name: 'Michigan Education Regional Program') }
  let(:monograph) { create(:monograph, title: ['Stuff'],
                                       creator_family_name: 'Worm',
                                       creator_given_name: 'Bird',
                                       description: ['Things about Stuff'],
                                       subject: ['Birds', 'Bionics', 'Hats'],
                                       date_published: ['1776'],
                                       isbn: ['123-456-7890'],
                                       press: press.subdomain,
                                       publisher: [press.name]) }

  let(:file_set) { create(:file_set, title: ['Songs of Stuff'],
                                     description: ['Description about things'],
                                     creator_family_name: 'Ronald',
                                     creator_given_name: 'Ron',
                                     search_year: '2025') }
  before do
    monograph.ordered_members << file_set
    monograph.save!
  end

  describe "#monograph_coins_title" do
    let(:solr_doc) { SolrDocument.new(monograph.to_solr) }
    let(:presenter) { CurationConcerns::MonographPresenter.new(solr_doc, nil) }

    it "has the correct metadata" do
      kevs = presenter.monograph_coins_title

      expect(CGI.unescape(kevs)).to match("rft.au=Worm, Bird")
      expect(CGI.unescape(kevs)).to match("rft.title=Stuff")
      expect(CGI.unescape(kevs)).to match("rft.description=Things about Stuff")
      expect(kevs).to match("rft.subject=Bionics")
      expect(kevs).to match("rft.subject=Birds")
      expect(kevs).to match("rft.subject=Hats")
      expect(kevs).to match("rft.date=1776")
      expect(kevs).to match("rft.isbn=123-456-7890")
      expect(CGI.unescape(kevs)).to match("rft.publisher=Michigan Education Regional Program")
    end
  end

  describe '#file_set_coins_title' do
    let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
    let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_doc, nil) }

    it "has the correct metadata" do
      kevs = presenter.file_set_coins_title

      expect(CGI.unescape(kevs)).to match("rft.au=Ronald, Ron")
      expect(CGI.unescape(kevs)).to match("rft.title=Songs of Stuff")
      expect(CGI.unescape(kevs)).to match("rft.description=Description about things")
      expect(kevs).to match("rft.subject=Bionics")
      expect(kevs).to match("rft.subject=Birds")
      expect(kevs).to match("rft.subject=Hats")
      expect(kevs).to match("rft.date=2025")
    end
  end
end
