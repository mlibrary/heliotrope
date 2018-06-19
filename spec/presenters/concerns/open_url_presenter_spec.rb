# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenUrlPresenter do
  let(:mono_doc) { SolrDocument.new(id: '1',
                                    title_tesim: ['Stuff'],
                                    creator_full_name_tesim: ['Worm, Bird'],
                                    description_tesim: ['Things about Stuff'],
                                    subject_tesim: ['Birds', 'Bionics', 'Hats'],
                                    date_published_tesim: ['1776'],
                                    isbn_tesim: ['123-456-7890'],
                                    publisher_tesim: ['MERP']) }

  let(:file_set_doc) { SolrDocument.new(id: '2',
                                        title_tesim: ['Songs of Stuff'],
                                        description_tesim: ['Description about things'],
                                        creator_full_name_tesim: ['Ronald, Ron'],
                                        sort_date_tesim: ['2025-01-01'],
                                        monograph_id_ssim: ['1']) }

  describe "#monograph_coins_title" do
    let(:presenter) { Hyrax::MonographPresenter.new(mono_doc, nil) }

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
      expect(CGI.unescape(kevs)).to match("rft.publisher=MERP")
    end
  end

  describe '#file_set_coins_title' do
    let(:presenter) { Hyrax::FileSetPresenter.new(file_set_doc, nil) }

    it "has the correct metadata" do
      allow(presenter).to receive(:monograph).and_return(Hyrax::MonographPresenter.new(mono_doc, nil))

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
