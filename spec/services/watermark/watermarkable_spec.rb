# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Watermark::Watermarkable do
  let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', watermark?: true) }
  let(:noid) { '999999999' }
  let(:ebook) do
    instance_double(
      Sighrax::Ebook, 'ebook',
      noid: noid,
      data: {},
      valid?: true,
      parent: parent,
      title: 'title',
      resource_token: 'resource_token',
      filename: 'lorum_ipsum_toc.pdf',
      watermarkable?: true,
      publisher: publisher
    )
  end
  let(:parent) { instance_double(Sighrax::Ebook, title: 'title') }

  before do
    class FakeObject
      include Watermark::Watermarkable

      def current_institution
        Greensub::Institution.new(identifier: 1, name: "University of Michigan")
      end

      def initialize(ebook)
        @entity = @ebook = ebook
      end
    end
  end

  let(:object) { FakeObject.new(ebook) }

  describe "#watermark_formatted_text" do
    let(:solr_document) { double("solr_document", license: ["http://url.for.cc.license.com"]) }
    let(:presenter) { instance_double(Hyrax::MonographPresenter,
                                      id: 'validnoid',
                                      citations_ready?: true,
                                      authors: 'Ann Author and Ann Other',
                                      epub?: false,
                                      pdf_ebook?: true,
                                      license?: true,
                                      license_abbreviated: "CC BY 4.0 DEED",
                                      solr_document: solr_document,
                                      creator: ['Doe, A. Deer'],
                                      title: ['A Reasonably Long Title'],
                                      date_created: ['2001'],
                                      based_near_label: ['Ann Arbor'],
                                      citable_link: 'https://doi.org/some/doi',
                                      publisher: ['University of Michigan Press'],
                                      to_s: "A Reasonably Long Title") }

    before do
      allow(Sighrax).to receive(:hyrax_presenter).with(parent).and_return(presenter)
    end

    it "generates the correctly formatted text" do
      expect(object.watermark_formatted_text).to eq [
        { text: "Doe, A. Deer. " },
        { styles: [:italic], text: "A Reasonably Long Title." },
        { text: "\n" },
        { text: "E-book, Ann Arbor: University of Michigan Press, 2001, " },
        { link: "https://doi.org/some/doi", text: "https://doi.org/some/doi" },
        { text: "." },
        { text: "\n" },
        { link: "https://url.for.cc.license.com", text: "CC BY 4.0 DEED" },
        { text: "\nDownloaded on behalf of University of Michigan" }
      ]
    end

    context "with a really long title" do
      let(:long_title) { "This Title is Very Long, has a Series of Digressions as well as not only a Very Long Subtitle: That Itself is Probably too Long: But Also a Sub-Subtitle, if That's Even a Thing" }

      before do
        allow(presenter).to receive(:to_s).and_return(long_title)
      end

      # Where we break up a long title or long publisher is determined by the
      #   magic_max_char_width_number
      # variable. If that changes these specs will need to change.
      it "generates the correctly formatted text, the title has a newline in it" do
        expect(object.watermark_formatted_text).to eq [
          { text: "Doe, A. Deer. " },
          { styles: [:italic], text: "This Title Is Very Long, Has a Series of Digressions As Well As Not Only a Very Long Subtitle: That Itself Is Probably Too Long: But Also a\nSub-Subtitle, If That's Even a Thing." },
          { text: "\n" },
          { text: "E-book, Ann Arbor: University of Michigan Press, 2001, " },
          { link: "https://doi.org/some/doi", text: "https://doi.org/some/doi" },
          { text: "." },
          { text: "\n" },
          { link: "https://url.for.cc.license.com", text: "CC BY 4.0 DEED" },
          { text: "\nDownloaded on behalf of University of Michigan" }
        ]
      end
    end

    context "with a handle, not a DOI" do
      before do
        allow(presenter).to receive(:citable_link).and_return("https://hdl.handle.net/2027/something")
      end

      it "generates the correctly formated text with a linked handle" do
        expect(object.watermark_formatted_text).to eq [
          { text: "Doe, A. Deer. " },
          { styles: [:italic], text: "A Reasonably Long Title." },
          { text: "\n" },
          { text: "E-book, Ann Arbor: University of Michigan Press, 2001, " },
          { link: "https://hdl.handle.net/2027/something", text: "https://hdl.handle.net/2027/something" },
          { text: "." },
          { text: "\n" },
          { link: "https://url.for.cc.license.com", text: "CC BY 4.0 DEED" },
          { text: "\nDownloaded on behalf of University of Michigan" }
        ]
      end
    end

    context "with a really long publisher" do
      let(:long_publisher) { ["There Is a Group of Young People With Dreams, Who Believe They Can Make the Wonders of Life for All the People Who Have Ever Been or Who Will Be University Press of The World"] }
      before do
        allow(presenter).to receive(:publisher).and_return(long_publisher)
      end

      it "generates the correcly formed text with a line break in the publisher" do
        expect(object.watermark_formatted_text).to eq [
          { text: "Doe, A. Deer. " },
          { styles: [:italic], text: "A Reasonably Long Title." },
          { text: "\n" },
          { text: "E-book, Ann Arbor: There Is a Group of Young People With Dreams, Who Believe They Can Make the Wonders of Life for All the People Who Have Ever Been or Who Will\nBe University Press of The World, 2001, " },
          { link: "https://doi.org/some/doi", text: "https://doi.org/some/doi" },
          { text: "." },
          { text: "\n" },
          { link: "https://url.for.cc.license.com", text: "CC BY 4.0 DEED" },
          { text: "\nDownloaded on behalf of University of Michigan" }
        ]
      end
    end
  end
end
