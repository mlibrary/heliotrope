# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KbartUtils::AddRecord do
  subject { KbartUtils::AddRecord }

  describe "#create_or_update" do
    context "when the kbart row doesn't exist yet" do
      let(:press) { create(:press, subdomain: "heb", name: "ACLS") }
      let(:monograph) { create(:public_monograph, id: "999999999",
                                                  title: ["_Markdown_ Yellow"],
                                                  press: "heb",
                                                  isbn: ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (ebook)"],
                                                  publisher: ["Blue Press"],
                                                  creator: ["Lastname, Firstname\nOtherlast, Otherfirst"],
                                                  identifier: ["heb_id:heb99999.0001.001"]) }

      it "creates a new kbart row" do
        expect { subject.create_or_update(monograph) }.to change(Kbart, :count).by(1)

        kbart = Kbart.first

        expect(kbart.publication_title).to eq "Markdown Yellow"
        expect(kbart.print_identifier).to eq "9780472075812"
        expect(kbart.online_identifier).to eq "9780472903139"
        expect(kbart.title_url).to eq "https://hdl.handle.net/2027/fulcrum.999999999"
        expect(kbart.first_author).to eq "Lastname"
        expect(kbart.title_id).to eq "HEB99999.0001.001"
        expect(kbart.coverage_depth).to eq "fulltext"
        expect(kbart.publisher_name).to eq "Blue Press"
      end
    end

    context "when there's already a row for this monograph" do
      let(:press) { create(:press, subdomain: "bar", name: "BAR Digital Collection") }
      let(:monograph) { create(:public_monograph, id: "999999999",
                                                  title: ["The Title"],
                                                  press: "bar",
                                                  doi: "10.30861/9781407359335",
                                                  isbn: ["978-0-472-05581-4 (paper)", "978-0-472-90313-9 (ebook pdf)"],
                                                  publisher: ["Blue Press"],
                                                  creator: ["Lastname, Firstname\nOtherlast, Otherfirst"]) }

      before do
        travel_to(Time.zone.parse("2015-01-01 00:00:00")) do
          subject.create_or_update(monograph)
        end
      end

      it "updates the updated_at field" do
        travel_to(Time.zone.parse("2025-01-01  00:00:00")) do
          subject.create_or_update(monograph)

          kbart = Kbart.first

          expect(kbart.updated_at).to eq "2025-01-01 00:00:00"
        end
      end
    end
  end

  describe "#first_author_last_name" do
    let(:monograph) { double("monograph", creator: ["Lastname, Firstname\nOtherlast, Otherfirst"]) }

    it "returns the first author's last name" do
      expect(subject.first_author_last_name(monograph)).to eq "Lastname"
    end
  end

  describe "#print_isbn" do
    context "a normal book with multiple ISBNS" do
      isbns = ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (open access)"]

      it "returns the unformated hardcover ISBN" do
        expect(subject.print_isbn(isbns)).to eq "9780472075812"
      end
    end

    context "with 'print' type" do
      isbns = ["978-0-472-07581-2 (print)", "978-0-472-90313-9 (open access)"]

      it "returns the print ISBN" do
        expect(subject.print_isbn(isbns)).to eq "9780472075812"
      end
    end

    context "with no print ISBNs" do
      isbns = ["978-0-472-07581-2 (ebook)", "978-0-472-05581-4 (pdf)", "978-0-472-90313-9 (open access)"]

      it "returns an empty string" do
        expect(subject.print_isbn(isbns)).to eq ""
      end
    end

    context "with no ISBN types" do
      isbns = ["978-0-472-90313-9"]

      it "returns an empty string" do
        expect(subject.print_isbn(isbns)).to eq ""
      end
    end

    context "with no ISBNs" do
      isbns = []

      it "returns an empty string" do
        expect(subject.print_isbn(isbns)).to eq ""
      end
    end
  end

  describe "#online_isbn" do
    context "a normal book with multiple ISBNs" do
      isbns = ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (open access)"]

      it "returns the unformated open access ISBN" do
        expect(subject.online_isbn(isbns)).to eq "9780472903139"
      end
    end

    context "with both ebook and open access types" do
      isbns = ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (ebook)", "978-0-472-90313-9 (open access)"]

      it "returns the open access isbn" do
        expect(subject.online_isbn(isbns)).to eq "9780472903139"
      end
    end

    context "with just the ebook" do
      isbns = ["978-0-472-07581-2 (hardcover)", "978-0-472-05581-4 (paper)", "978-0-472-90313-9 (ebook)"]

      it "returns the ebook isbn" do
        expect(subject.online_isbn(isbns)).to eq "9780472903139"
      end
    end
  end

  describe "#title_url" do
    context "if there's a DOI" do
      let(:monograph) { double("monograph", doi: "10.3998/mpub.11691056") }

      it "returns the DOI" do
        expect(subject.title_url(monograph)).to eq "https://doi.org/10.3998/mpub.11691056"
      end
    end

    context "if there's a hdl property on the monograph" do
      let(:monograph) { double("monograph", doi: nil, hdl: "2027/spo.13469761.0014.001") }

      it "returns the monograph hdl" do
        expect(subject.title_url(monograph)).to eq "https://hdl.handle.net/2027/spo.13469761.0014.001"
      end
    end

    context "if there's no doi or hdl property" do
      let(:monograph) { double("monograph", doi: nil, hdl: nil, id: "999999999") }

      it "returns the default fulcrum handle" do
        expect(subject.title_url(monograph)).to eq "https://hdl.handle.net/2027/fulcrum.999999999"
      end
    end
  end

  describe "#title_id" do
    context "if it's heb" do
      let(:monograph) { double("monograph", press: "heb", identifier: ["heb_id:heb90000.0001.001", "something else"]) }

      it "returns the capitalized hebid" do
        expect(subject.title_id(monograph)).to eq "HEB90000.0001.001"
      end
    end

    context "if there's a doi" do
      let(:monograph) { double("monograph", press: "other", doi: "10.3998/mpub.11691056") }

      it "returns the doi, not the doi url" do
        expect(subject.title_id(monograph)).to eq "10.3998/mpub.11691056"
      end
    end

    context "if there's a hdl property but no doi" do
      let(:monograph) { double("monograph", press: "other", doi: nil, hdl: "2027/spo.13469761.0014.001") }

      it "returns the hdl property" do
        expect(subject.title_id(monograph)).to eq "2027/spo.13469761.0014.001"
      end
    end

    context "if it's not heb, there's no doi and no explicit hdl property" do
      let(:monograph) { double("monograph", id: "999999999", press: "other", doi: nil, hdl: nil) }

      it "returns the default fulcrum handle, not handle url" do
        expect(subject.title_id(monograph)).to eq "2027/fulcrum.999999999"
      end
    end
  end

  describe "#publisher_name" do
    context "if it's bar" do
      let(:monograph) { double("monograph", press: "bar") }

      it "returns 'British Archaeological Reports'" do
        expect(subject.publisher_name(monograph)).to eq "British Archaeological Reports"
      end
    end

    context "if it's heb" do
      let(:monograph) { double("monograph", press: "heb", publisher: ["Oxford Press"]) }

      it "returns the monograph's publisher property" do
        expect(subject.publisher_name(monograph)).to eq "Oxford Press"
      end
    end

    context "all other presses" do
      let(:press) { create(:press, subdomain: "otherpress", name: "The Name of the Press") }
      let(:monograph) { double("monograph", press: press.subdomain) }

      it "returns the press name" do
        expect(subject.publisher_name(monograph)).to eq "The Name of the Press"
      end
    end
  end
end
