# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildKbartJob, type: :job do
  let(:doc_a) do
    SolrDocument.new(id: "aaaaaaaaa",
                     title_tesim: ["A Book _Italic_"],
                     creator_tesim: ["Adams, Firstname"],
                     isbn_tesim: ["A123456789 (hardcover)", "A987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.A",
                     press_name_ssim: ["A Press"],
                     visibility_ssi: "open")
  end

  let(:doc_b) do
    SolrDocument.new(id: 'bbbbbbbbb',
                     title_tesim: ["B Book _Italic_"],
                     creator_tesim: ["Brock, Firstname"],
                     isbn_tesim: ["B123456789 (hardcover)", "B987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.B",
                     press_name_ssim: ["B Press"],
                     visibility_ssi: "open")
  end

  let(:doc_c) do
    SolrDocument.new(id: 'ccccccccc',
                     title_tesim: ["C Book _Italic_"],
                     creator_tesim: ["Cassidy, Firstname"],
                     isbn_tesim: ["C123456789 (hardcover)", "C987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.C",
                     press_name_ssim: ["C Press"],
                     visibility_ssi: "open")
  end

  let(:doc_d) do
    SolrDocument.new(id: 'ddddddddd',
                     title_tesim: ["D Book _Italic_"],
                     creator_tesim: ["Davidson, Firstname"],
                     isbn_tesim: ["D123456789 (hardcover)", "D987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.D",
                     press_name_ssim: ["D Press"],
                     visibility_ssi: 'restricted')
  end

  subject { BuildKbartJob.new }

  describe "#perform" do
    let(:product) { create(:product, identifier: 'product', needs_kbart: true, group_key: 'product_key') }
    let(:test_root) { Rails.root.join('tmp', 'spec', 'public', 'products', product.group_key, 'kbart') }
    let(:old_kbart) do <<~KBART
publication_title,print_identifier,online_identifier,date_first_issue_online,num_first_vol_online,num_first_issue_online,date_last_issue_online,num_last_vol_online,num_last_issue_online,title_url,first_author,title_id,embargo_info,coverage_depth,coverage_notes,publisher_name
A Book Italic,A123456789,A987654321,"","","","","","",https://doi.org/10.3998/mpub.A,Adams,10.3998/mpub.A,"",fulltext,A Press
B Book Italic,B123456789,B987654321,"","","","","","",https://doi.org/10.3998/mpub.B,Brock,10.3998/mpub.B,"",fulltext,B Press
C Book Italic,C123456789,C987654321,"","","","","","",https://doi.org/10.3998/mpub.C,Cassidy,10.3998/mpub.C,"",fulltext,C Press
    KBART
    end

    before do
      FileUtils.rm_rf(test_root)

      product.components = [
        create(:component, noid: doc_c.id),
        create(:component, noid: doc_b.id),
        create(:component, noid: doc_d.id),
        create(:component, noid: doc_a.id)
      ]

      ActiveFedora::SolrService.add([doc_c.to_h, doc_b.to_h, doc_d.to_h, doc_a.to_h])
      ActiveFedora::SolrService.commit
    end

    context "when there are no updates" do
      before do
        FileUtils.mkdir_p(test_root)
        File.write(Rails.root.join(test_root, "product_2022-01-01.csv"), old_kbart)
      end

      it "does not create a new kbart file" do
        travel_to("2022-02-02") do
          subject.perform_now

          expect(Dir.glob(test_root + "*").count).to eq 1
          expect(File.exist?(Rails.root.join(test_root, "product_2022-01-01.csv"))).to be true
          expect(File.exist?(Rails.root.join(test_root, "product_2022-02-02.csv"))).to be false
        end
      end
    end

    context "when there's an update" do
      let(:doc_e) do
        SolrDocument.new(id: 'eeeeeeeee',
                         title_tesim: ["E Book _Italic_"],
                         creator_tesim: ["Edwards, Firstname"],
                         isbn_tesim: ["E123456789 (hardcover)", "E987654321 (ebook)"],
                         doi_ssim: "10.3998/mpub.E",
                         press_name_ssim: ["E Press"],
                         visibility_ssi: "open")
      end

      before do
        product.components << create(:component, noid: doc_e.id)

        ActiveFedora::SolrService.add([doc_e.to_h])
        ActiveFedora::SolrService.commit

        FileUtils.mkdir_p(test_root)
        File.write(Rails.root.join(test_root, "product_2022-01-01.csv"), old_kbart)
      end

      it "creates new kbart files, .csv and .txt" do
        travel_to("2022-02-02") do
          subject.perform_now

          expect(Dir.glob(test_root + "*").count).to eq 3
          expect(File.exist?(Rails.root.join(test_root, "product_2022-01-01.csv"))).to be true
          expect(File.exist?(Rails.root.join(test_root, "product_2022-02-02.csv"))).to be true
          expect(File.exist?(Rails.root.join(test_root, "product_2022-02-02.txt"))).to be true

          # sneak in a check for the txt/tsv here I guess
          tsv = CSV.read(Rails.root.join(test_root, "product_2022-02-02.txt"), col_sep: "\t")

          expect(tsv[0][0]).to eq "publication_title"
          expect(tsv[1][0]).to eq "A Book Italic"
          expect(tsv[2][0]).to eq "B Book Italic"
          expect(tsv[3][0]).to eq "C Book Italic"
          expect(tsv[4][0]).to eq "E Book Italic"
        end
      end
    end

    context "when there are no existing kbart files" do
      before do
        FileUtils.mkdir_p(test_root)
      end

      it "creates new kbart files (csv and txt)" do
        travel_to("2022-02-02") do
          subject.perform_now

          expect(Dir.glob(test_root + "*").count).to eq 2
          expect(File.exist?(Rails.root.join(test_root, "product_2022-02-02.csv"))).to be true
          expect(File.exist?(Rails.root.join(test_root, "product_2022-02-02.txt"))).to be true
        end
      end
    end
  end

  describe "#published_sorted_monographs" do
    let(:product) { create(:product, identifier: 'product', needs_kbart: true, group_key: 'product') }

    before do
      product.components = [
        create(:component, noid: doc_c.id),
        create(:component, noid: doc_b.id),
        create(:component, noid: doc_d.id),
        create(:component, noid: doc_a.id)
      ]

      ActiveFedora::SolrService.add([doc_c.to_h, doc_b.to_h, doc_d.to_h, doc_a.to_h])
      ActiveFedora::SolrService.commit
    end

    it "returns the title sorted presenters of published monographs that belong to the product" do
      monographs = subject.published_sorted_monographs(product)

      expect(monographs.count).to eq 3
      expect(monographs[0]).to be_an_instance_of(Hyrax::MonographPresenter)
      expect(monographs[0].page_title).to eq "A Book Italic"
      expect(monographs[1].page_title).to eq "B Book Italic"
      expect(monographs[2].page_title).to eq "C Book Italic"
    end
  end

  describe "#most_recent_kbart" do
    let(:product) { create(:product, identifier: 'product', needs_kbart: true, group_key: 'product_key') }
    let(:test_root) { Rails.root.join('tmp', 'spec', 'public', 'products', product.group_key, 'kbart') }

    before do
      FileUtils.rm_rf(test_root)
      FileUtils.mkdir_p(test_root)
      FileUtils.touch(Rails.root.join(test_root, "product_2022-01-01.csv"))
      FileUtils.touch(Rails.root.join(test_root, "product_2022-02-01.csv"))
      FileUtils.touch(Rails.root.join(test_root, "product_2020-01-01.csv"))
    end

    it "returns the most recent kbart file for the product" do
      expect(subject.most_recent_kbart(test_root, product.identifier)).to eq Rails.root.join(test_root, "product_2022-02-01.csv").to_s
    end
  end

  describe "#kbart_root" do
    let(:product) { create(:product, identifier: 'product', needs_kbart: true, group_key: 'product_key') }

    it "returns the kbart root directory for the product" do
      expect(subject.kbart_root(product).to_s).to match(/public\/products\/product_key\/kbart/)
    end
  end

  describe "#make_kbart_csv" do
    let(:monographs) do
      [
        Hyrax::MonographPresenter.new(doc_a, nil),
        Hyrax::MonographPresenter.new(doc_b, nil),
        Hyrax::MonographPresenter.new(doc_c, nil)
      ]
    end

    it "makes a csv with a header" do
      csv = CSV.parse(subject.make_kbart_csv(monographs))

      expect(csv[0][0]).to eq "publication_title"
      expect(csv[0][15]).to eq "publisher_name"

      expect(csv[1][0]).to eq "A Book Italic"
      expect(csv[2][0]).to eq "B Book Italic"
      expect(csv[3][0]).to eq "C Book Italic"
    end
  end

  describe "#first_author_last_name" do
    let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(creator_tesim: ["Lastname, Firstname\nOtherlast, Otherfirst"]), nil) }

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
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(doi_ssim: "10.3998/mpub.11691056"), nil) }

      it "returns the DOI" do
        expect(subject.title_url(monograph)).to eq "https://doi.org/10.3998/mpub.11691056"
      end
    end

    context "if there's a hdl property on the monograph" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(hdl_ssim: "2027/spo.13469761.0014.001"), nil) }

      it "returns the monograph hdl" do
        expect(subject.title_url(monograph)).to eq "https://hdl.handle.net/2027/spo.13469761.0014.001"
      end
    end

    context "if there's no doi or hdl property" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(id: "999999999"), nil) }

      it "returns the default fulcrum handle" do
        expect(subject.title_url(monograph)).to eq "https://hdl.handle.net/2027/fulcrum.999999999"
      end
    end
  end

  describe "#title_id" do
    context "if it's heb" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_tesim: ["heb"], identifier_tesim: ["heb_id:heb90000.0001.001", "something else"]), nil) }

      it "returns the capitalized hebid" do
        expect(subject.title_id(monograph)).to eq "HEB90000.0001.001"
      end
    end

    context "if there's a doi" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_tesim: ["other"], doi_ssim: ["10.3998/mpub.11691056"]), nil) }

      it "returns the doi, not the doi url" do
        expect(subject.title_id(monograph)).to eq "10.3998/mpub.11691056"
      end
    end

    context "if there's a hdl property but no doi" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_tesim: ["other"], hdl_ssim: ["2027/spo.13469761.0014.001"]), nil) }


      it "returns the hdl property" do
        expect(subject.title_id(monograph)).to eq "2027/spo.13469761.0014.001"
      end
    end

    context "if it's not heb, there's no doi and no explicit hdl property" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(id: "999999999", press_tesim: ["other"]), nil) }

      it "returns the default fulcrum handle, not handle url" do
        expect(subject.title_id(monograph)).to eq "2027/fulcrum.999999999"
      end
    end
  end

  describe "#publisher_name" do
    context "if it's barpublishing" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_tesim: ["barpublishing"]), nil) }

      it "returns 'British Archaeological Reports'" do
        expect(subject.publisher_name(monograph)).to eq "British Archaeological Reports"
      end
    end

    context "if it's heb" do
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_tesim: ["heb"], publisher_tesim: ["Oxford Press"]), nil) }

      it "returns the monograph's publisher property" do
        expect(subject.publisher_name(monograph)).to eq "Oxford Press"
      end
    end

    context "all other presses" do
      # It's probably a long ago mistake that a press name is indexed on the Monograph as _ssim but ok
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(press_name_ssim: ["The Name of the Press"]), nil) }

      it "returns the press name" do
        expect(subject.publisher_name(monograph)).to eq "The Name of the Press"
      end
    end
  end
end
