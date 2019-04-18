# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crossref::Metadata do
  let(:press) { create(:press, subdomain: "blue", name: "The Blue Press") }

  let(:monograph) do
    ::SolrDocument.new(id: '999999999',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['A Title'],
                       creator_tesim: ["Last, First\nSecondLast, SecondFirst"],
                       importable_creator_ss: "Last, First; SecondLast, SecondFirst",
                       press_tesim: [press.subdomain],
                       isbn_tesim: ["1234567890 (ebook)", "0987654321 (hardcover)"],
                       date_created_tesim: ['9999'])
  end

  before do
    ActiveFedora::SolrService.add([monograph.to_h])
    ActiveFedora::SolrService.commit
  end

  describe "#initialize" do
    subject { described_class.new(monograph.id) }

    it "work is a Monograph" do
      expect(subject.work).is_a? Hyrax::MonographPresenter
    end
  end

  describe "#book_type" do
    context "with editors" do
      subject { described_class.new(edited_book.id) }

      let(:edited_book) do
        ::SolrDocument.new(id: '111111111',
                           has_model_ssim: ['Monograph'],
                           title_tesim: ['A Title'],
                           creator_tesim: ["Last, First (editor)\nSecondLast, SecondFirst (editor)"],
                           importable_creator_ss: "Last, First (editor); SecondLast, SecondFirst (editor)",
                           press_tesim: [press.subdomain],
                           isbn_tesim: ["1234567890 (ebook)", "0987654321 (hardcover)"],
                           date_created_tesim: ['9999'])
      end

      before do
        ActiveFedora::SolrService.add([edited_book.to_h])
        ActiveFedora::SolrService.commit
        allow(subject.work).to receive(:creator_display?).and_return(false)
      end

      it "is an 'edited_book'" do
        subject.book_type
        expect(subject.document.at_css("book").attribute("book_type").value).to eq "edited_book"
      end
    end

    context "without editors" do
      subject { described_class.new(monograph.id) }

      it "is a 'monograph'" do
        subject.book_type
        expect(subject.document.at_css("book").attribute("book_type").value).to eq "monograph"
      end
    end
  end

  describe "#contributors" do
    subject { described_class.new(monograph.id) }

    it "has the correct contributors" do
      subject.contributors

      first = subject.document.at_css('contributors person_name[sequence="first"]')
      expect(first.attribute("contributor_role").value).to eq "author"
      expect(first.at_css('given_name').content).to eq "First"
      expect(first.at_css('surname').content).to eq "Last"

      additional = subject.document.at_css('contributors person_name[sequence="additional"]')
      expect(additional.attribute("contributor_role").value).to eq "author"
      expect(additional.at_css('given_name').content).to eq "SecondFirst"
      expect(additional.at_css('surname').content).to eq "SecondLast"
    end
  end

  describe "#doi_batch_id" do
    subject { described_class.new(monograph.id) }

    let(:timestamp) { "20190419111616" }

    before { allow_any_instance_of(described_class).to receive(:timestamp).and_return(timestamp) }

    it "has the correct doi_batch_id" do
      subject.doi_batch_id

      expect(subject.document.at_css('doi_batch_id').content).to eq "blue-#{monograph.id}-#{timestamp}"
    end
  end

  describe "#set_timestamp" do
    subject { described_class.new(monograph.id) }

    let(:timestamp) { "20190419111616" }

    before { allow_any_instance_of(described_class).to receive(:timestamp).and_return(timestamp) }

    it "has the correct timestamp" do
      subject.set_timestamp

      expect(subject.document.at_css('timestamp').content).to eq timestamp
    end
  end

  describe "#title" do
    subject { described_class.new(monograph.id) }

    it "has the correct title" do
      subject.title

      expect(subject.document.at_css('title').content).to eq subject.work.title
    end
  end

  describe "#publication_date" do
    subject { described_class.new(monograph.id) }

    it "has the correct publication_date" do
      subject.publication_date

      expect(subject.document.at_css('publication_date/year').content).to eq '9999'
    end
  end

  describe "#isbn_media_type" do
    context "with a media type" do
      subject { described_class.new(monograph.id).isbn_media_type("999999999 (hardcover)") }

      it "returns the isbn and media type" do
        expect(subject).to eq ["999999999", "hardcover"]
      end
    end

    context "with no media type" do
      subject { described_class.new(monograph.id).isbn_media_type("999999999") }

      it "returns the isbn and media type" do
        expect(subject).to eq ["999999999", ""]
      end
    end
  end

  describe "#probably_ebook?" do
    subject { described_class.new(monograph.id) }

    it "returns true" do
      ["ebook", "electronic format", "E-Book", "E-book", "eBook : Adobe Reader", "e-book : Adobe Reader", "electronic", "open access", "ebk."].each do |media_type|
        expect(subject.probably_ebook?(media_type)).to be true
      end
    end
    it "returns false" do
      ["hardcover", "paper", "pbk.", "hbd.", "paper binding : alk. paper", "random", "weird", "stuff"].each do |media_type|
        expect(subject.probably_ebook?(media_type)).to be false
      end
    end
  end

  describe "#isbns" do
    subject { described_class.new(monograph.id) }

    it "has isbns with correct media types" do
      subject.isbns
      expect(subject.document.at_css('isbn[media_type="electronic"]').content).to eq "1234567890"
      expect(subject.document.at_css('isbn[media_type="print"]').content).to eq "0987654321"
    end
  end

  describe "#publisher_name" do
    subject { described_class.new(monograph.id) }

    it "has the correct publisher name" do
      subject.publisher_name

      expect(subject.document.at_css('publisher_name').content).to eq press.name
    end
  end

  describe "#doi" do
    # I *think* we're going to generally be making new DOIs automatically. And that if
    # a Monograph already has a DOI then there's a very high chance it's already been registered.
    # But I'm not sure. So we'll register the Monograph's DOI if it has a value in it's doi field,
    # otherwise we'll make one.
    subject { described_class.new(monograph.id) }

    let(:new_doi) { "10.3998/#{monograph.press}.#{monograph.id}" }
    let(:monograph_with_doi) { double('monograph_with_doi', doi: new_doi) }

    before do
      # We want to "put a pin" in the fact that we updated the monographs's doi in AF
      # but I don't think we need to actually test that AF is working.
      # So: lots of mocks/stubs.
      allow(Monograph).to receive(:find).with(monograph.id).and_return(monograph_with_doi)
      allow(monograph_with_doi).to receive(:doi=).and_return(true)
      allow(monograph_with_doi).to receive(:save).and_return(true)
    end

    it "has the correct doi" do
      subject.doi
      expect(subject.document.at_css('doi').content).to eq new_doi
      # And we've saved the new doi to the monograph
      # Is this too mocky? Probably.
      expect(monograph_with_doi.doi).to eq new_doi
    end
  end

  describe "#resource" do
    # I think we're pointing DOIs to Handles
    subject { described_class.new(monograph.id) }

    it "has the correct resource" do
      subject.resource
      expect(subject.document.at_css('resource').content).to eq "https://hdl.handle.net/2027/fulcrum.#{monograph.id}"
    end
  end
end
