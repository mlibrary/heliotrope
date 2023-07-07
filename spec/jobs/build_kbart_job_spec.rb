# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe BuildKbartJob, type: :job do
  let(:doc_a) do
    SolrDocument.new(id: "aaaaaaaaa",
                     has_model_ssim: "Monograph",
                     title_tesim: ["A Book _Italic_"],
                     creator_tesim: ["Adams, Firstname"],
                     isbn_tesim: ["A123456789 (hardcover)", "A987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.A",
                     press_name_ssim: ["A Press"],
                     visibility_ssi: "open",
                     date_published_dtsim: ["2023-03-30T15:04:53Z"],
                     products_lsim: [product.id])
  end

  let(:doc_b) do
    SolrDocument.new(id: 'bbbbbbbbb',
                     has_model_ssim: "Monograph",
                     title_tesim: ["B Book _Italic_"],
                     creator_tesim: ["Brock, Firstname"],
                     isbn_tesim: ["B123456789 (hardcover)", "B987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.B",
                     press_name_ssim: ["B Press"],
                     visibility_ssi: "open",
                     volume_tesim: ["Vol 1"],
                     edition_name_tesim: ["Second Edition"],
                     date_published_dtsim: ["2023-02-20T15:04:53Z"],
                     products_lsim: [product.id])
  end

  let(:doc_c) do
    SolrDocument.new(id: 'ccccccccc',
                     has_model_ssim: "Monograph",
                     title_tesim: ["C Book _Italic_"],
                     creator_tesim: ["Cassidy, Firstname"],
                     isbn_tesim: ["C987654321 (open access)"],
                     doi_ssim: "10.3998/mpub.C",
                     press_name_ssim: ["C Press"],
                     open_access_tesim: ["yes"],
                     visibility_ssi: "open",
                     date_published_dtsim: ["2023-01-10T15:04:53Z"],
                     products_lsim: [product.id])
  end

  let(:doc_d) do
    SolrDocument.new(id: 'ddddddddd',
                     has_model_ssim: "Monograph",
                     title_tesim: ["D Book _Italic_"],
                     creator_tesim: ["Davidson, Firstname"],
                     isbn_tesim: ["D123456789 (hardcover)", "D987654321 (ebook)"],
                     doi_ssim: "10.3998/mpub.D",
                     press_name_ssim: ["D Press"],
                     visibility_ssi: 'restricted',
                     date_published_dtsim: ["2000-01-01T15:04:53Z"],
                     products_lsim: [product.id])
  end

  subject { BuildKbartJob.new }

  describe "#perform" do
    let(:product) { create(:product, identifier: 'test_product', needs_kbart: true, group_key: 'test_product') }
    let(:test_root) { File.join(Settings.scratch_space_path, 'spec', 'public', 'products', product.group_key, 'kbart') }
    let(:old_kbart) do <<~KBART
"publication_title","print_identifier","online_identifier","date_first_issue_online","num_first_vol_online","num_first_issue_online","date_last_issue_online","num_last_vol_online","num_last_issue_online","title_url","first_author","title_id","embargo_info","coverage_depth","notes","publisher_name","publication_type","date_monograph_published_print","date_monograph_published_online","monograph_volume","monograph_edition","first_editor","parent_publication_title_id","preceding_publication_title_id","access_type"
"A Book Italic","A123456789","A987654321","","","","","","","https://doi.org/10.3998/mpub.A","Adams","10.3998/mpub.A","","fulltext","","A Press","monograph","2023-03-30","2023-03-30","","","","","","P"
"B Book Italic","B123456789","B987654321","","","","","","","https://doi.org/10.3998/mpub.B","Brock","10.3998/mpub.B","","fulltext","","B Press","monograph","2023-02-20","2023-02-20","Vol 1","Second Edition","","","","P"
"C Book Italic","","C987654321","","","","","","","https://doi.org/10.3998/mpub.C","Cassidy","10.3998/mpub.C","","fulltext","","C Press","monograph","","2023-01-10","","","","","","F"
    KBART
    end
    let(:sftp) { double('sftp') }
    let(:login) { { fulcrum_sftp_credentials: { sftp: 'fake', user: 'fake', password: 'fake', root: '/' } }.with_indifferent_access }

    before do
      allow_any_instance_of(BuildKbartJob).to receive(:yaml_config).and_return(login)
      allow(Net::SFTP).to receive(:start).and_yield(sftp)
    end

    context "without components" do
      before do
        FileUtils.mkdir_p(test_root)
        File.write(File.join(test_root, "test_product_2022-01-01.csv"), old_kbart)

        ActiveFedora::SolrService.add([doc_c.to_h, doc_b.to_h, doc_d.to_h, doc_a.to_h])
        ActiveFedora::SolrService.commit
      end

      it "does not create a new kbart file" do
        travel_to("2022-02-02") do
          expect(Net::SFTP).not_to receive(:start)

          subject.perform_now

          expect(Dir.glob(test_root + "/*").count).to eq 1
          expect(File.exist?(File.join(test_root, "test_product_2022-01-01.csv"))).to be true
          expect(File.exist?(File.join(test_root, "test_product_2022-02-02.csv"))).to be false
        end
      end
    end

    context "with components" do
      context "with an unknown product group key" do
        let(:product) { create(:product, identifier: 'something', needs_kbart: true, group_key: 'unknown') }
        let(:test_root) { File.join(Settings.scratch_space_path, 'spec', 'public', 'products', product.group_key, 'kbart') }

        before do
          FileUtils.rm_rf(test_root)
          allow(Monograph).to receive(:find)

          product.components = [
            create(:component, noid: doc_c.id),
            create(:component, noid: doc_b.id),
            create(:component, noid: doc_d.id),
            create(:component, noid: doc_a.id)
          ]

          ActiveFedora::SolrService.add([doc_c.to_h, doc_b.to_h, doc_d.to_h, doc_a.to_h])
          ActiveFedora::SolrService.commit
        end

        after do
          FileUtils.mkdir_p(test_root)
        end

        it "does not create a new kbart file" do
          travel_to("2022-02-02") do
            FileUtils.mkdir_p(test_root)

            expect(Net::SFTP).not_to receive(:start)
            expect(Rails.logger).to receive(:error)

            subject.perform_now

            expect(Dir.glob(test_root + "/*").count).to eq 0
          end
        end
      end

      context "with a known product group key" do
        before do
          FileUtils.rm_rf(test_root)
          allow(Monograph).to receive(:find)

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
            File.write(File.join(test_root, "test_product_2022-01-01.csv"), old_kbart)
          end

          it "does not create a new kbart file" do
            travel_to("2022-02-02") do
              expect(Net::SFTP).not_to receive(:start)

              subject.perform_now

              expect(Dir.glob(test_root + "/*").count).to eq 1
              expect(File.exist?(File.join(test_root, "test_product_2022-01-01.csv"))).to be true
              expect(File.exist?(File.join(test_root, "test_product_2022-02-02.csv"))).to be false
            end
          end
        end

        context "when there's an update" do
          let(:doc_e) do
            SolrDocument.new(id: 'eeeeeeeee',
                            has_model_ssim: "Monograph",
                            title_tesim: ["E Book _Italic_"],
                            creator_tesim: ["Edwards, Firstname"],
                            isbn_tesim: ["E123456789 (hardcover)", "E987654321 (ebook)"],
                            doi_ssim: "10.3998/mpub.E",
                            press_name_ssim: ["E Press"],
                            visibility_ssi: "open",
                            date_published_dtsim: ["2022-02-22T15:04:53Z"],
                            products_lsim: [product.id])
          end
          let(:local_csv) { File.join(test_root, "test_product_2022-02-02.csv") }
          let(:local_tsv) { File.join(test_root, "test_product_2022-02-02.txt") }
          let(:remote_csv) { "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART/test_product_2022-02-02.csv" }
          let(:remote_tsv) { "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART/test_product_2022-02-02.txt" }

          before do
            allow(Monograph).to receive(:find)
            product.components << create(:component, noid: doc_e.id)

            ActiveFedora::SolrService.add([doc_e.to_h])
            ActiveFedora::SolrService.commit

            FileUtils.mkdir_p(test_root)
            File.write(File.join(test_root, "test_product_2022-01-01.csv"), old_kbart)

            allow(sftp).to receive(:upload!).and_return(true)
          end

          it "creates new kbart files, .csv and .txt" do
            travel_to("2022-02-02") do
              subject.perform_now

              expect(Net::SFTP).to have_received(:start)
              expect(sftp).to have_received(:upload!).with(local_csv, remote_csv).once
              expect(sftp).to have_received(:upload!).with(local_tsv, remote_tsv).once

              expect(Dir.glob(test_root + "/*").count).to eq 3
              expect(File.exist?(File.join(test_root, "test_product_2022-01-01.csv"))).to be true
              expect(File.exist?(File.join(test_root, "test_product_2022-02-02.csv"))).to be true
              expect(File.exist?(File.join(test_root, "test_product_2022-02-02.txt"))).to be true

              # sneak in a check for the txt/tsv here I guess
              tsv = CSV.read(File.join(test_root, "test_product_2022-02-02.txt"), col_sep: "\t")

              expect(tsv[0][0]).to eq "publication_title"
              expect(tsv[1][0]).to eq "A Book Italic"
              expect(tsv[2][0]).to eq "B Book Italic"
              expect(tsv[3][0]).to eq "C Book Italic"
              expect(tsv[4][0]).to eq "E Book Italic"
            end
          end
        end

        context "when there are no existing kbart files" do
          let(:local_csv) { File.join(test_root, "test_product_2022-02-02.csv") }
          let(:local_tsv) { File.join(test_root, "test_product_2022-02-02.txt") }
          let(:remote_csv) { "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART/test_product_2022-02-02.csv" }
          let(:remote_tsv) { "/home/fulcrum_ftp/heliotropium/publishing/Testing/KBART/test_product_2022-02-02.txt" }

          before do
            FileUtils.mkdir_p(test_root)
            allow(sftp).to receive(:upload!).and_return(true)
          end

          it "creates new kbart files (csv and txt)" do
            travel_to("2022-02-02") do
              subject.perform_now

              expect(Net::SFTP).to have_received(:start)
              expect(sftp).to have_received(:upload!).with(local_csv, remote_csv).once
              expect(sftp).to have_received(:upload!).with(local_tsv, remote_tsv).once

              expect(Dir.glob(test_root + "/*").count).to eq 2
              expect(File.exist?(File.join(test_root, "test_product_2022-02-02.csv"))).to be true
              expect(File.exist?(File.join(test_root, "test_product_2022-02-02.txt"))).to be true
            end
          end
        end
      end
    end
  end

  describe "#yaml_config" do
    context "no config" do
      it "returns nil" do
        expect(subject.yaml_config).to be nil
      end
    end

    context "with config" do
      let(:data) do
        {
          "fulcrum_sftp_credentials" => {
            "sftp" => 'ftp.fulcrum.org',
            "user" => 'username',
            "password" => 'password',
            "root" => '/'
          }
        }
      end
      let(:config_file) { Tempfile.new("fulcrum_sftp.yml") }

      before do
        allow(Rails.root).to receive(:join).with('config', 'fulcrum_sftp.yml').and_return(config_file)
      end

      it "returns login information" do
        config_file.write(data.to_yaml)
        config_file.rewind
        config = subject.yaml_config["fulcrum_sftp_credentials"]
        expect(config["sftp"]).to eq "ftp.fulcrum.org"
        expect(config["user"]).to eq "username"
        expect(config["password"]).to eq "password"
        expect(config["root"]).to eq "/"
      end
    end
  end

  describe "#published_sorted_monographs" do
    let(:product) { create(:product, identifier: 'test_product', needs_kbart: true, group_key: 'test_product') }

    before do
      allow(Monograph).to receive(:find)

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
    let(:product) { create(:product, identifier: 'test_product', needs_kbart: true, group_key: 'test_product') }
    let(:test_root) { File.join(Settings.scratch_space_path, 'spec', 'public', 'products', product.group_key, 'kbart') }

    before do
      FileUtils.rm_rf(test_root)
      FileUtils.mkdir_p(test_root)
      FileUtils.touch(File.join(test_root, "test_product_2022-01-01.csv"))
      FileUtils.touch(File.join(test_root, "test_product_2022-02-01.csv"))
      FileUtils.touch(File.join(test_root, "test_product_2020-01-01.csv"))
    end

    it "returns the most recent kbart file for the product" do
      expect(subject.most_recent_kbart(test_root, product.identifier)).to eq File.join(test_root, "test_product_2022-02-01.csv").to_s
    end
  end

  describe "#kbart_root" do
    let(:product) { create(:product, identifier: 'test_product', needs_kbart: true, group_key: 'test_product') }

    it "returns the kbart root directory for the product" do
      expect(subject.kbart_root(product).to_s).to match(/public\/products\/test_product\/kbart/)
    end
  end

  describe "#make_kbart_csv" do
    let(:product) { create(:product, identifier: 'test_product', needs_kbart: true, group_key: 'test_product') }
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
      expect(csv[0][24]).to eq "access_type"

      expect(csv[1][0]).to eq "A Book Italic"
      # not OA means access_type is "P"
      expect(csv[1][24]).to eq "P"

      expect(csv[2][0]).to eq "B Book Italic"
      # a print_isbn means a date_monograph_published_print
      expect(csv[2][1]).to eq "B123456789"
      expect(csv[2][17]).to eq "2023-02-20"
      expect(csv[2][19]).to eq "Vol 1"
      expect(csv[2][20]).to eq "Second Edition"

      expect(csv[3][0]).to eq "C Book Italic"
      # no print isbn means no date_monograph_published_print
      expect(csv[3][1]).to eq ""
      expect(csv[3][17]).to eq ""
      # open access mean access_type is F
      expect(csv[3][24]).to eq "F"
    end
  end

  describe "#first_author_last_name" do
    let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(creator_tesim: ["Lastname, Firstname\nOtherlast, Otherfirst"]), nil) }

    it "returns the first author's last name" do
      expect(subject.first_author_last_name(monograph)).to eq "Lastname"
    end

    context "when there is no name/creator" do
      # This shouldn't happen, but it has for historical HEB metadata, HELIO-4457
      let(:monograph) { Hyrax::MonographPresenter.new(SolrDocument.new(creator_tesim: [nil]), nil) }

      it "returns the empty string" do
        expect(subject.first_author_last_name(monograph)).to eq ""
      end
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
