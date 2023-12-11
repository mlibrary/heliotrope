# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PsiReportJob, type: :job do
  let(:press) { create(:press, subdomain: "michigan") }

  describe "perform" do
    context "with given start and end dates" do
      let(:report_time) { PsiReport::ReportTime.new("2022-02-14", "2022-06-11") }
      let(:file_path) { "/tmp/fulcrum_michigan_psi_report_2022-02-14_2022-06-11.ready.csv" }
      let(:remote_file_path) { "/imports/fulcrum_michigan_psi_report_2022-02-14_2022-06-11.ready.csv" }
      let(:report_sender) { double("report_sender", send_report: true) }
      let(:login) { { psi_credentials: { ftp: 'fake', user: 'fake', password: 'fake', root: '/imports' } }.with_indifferent_access }
      let(:sftp) { double('sftp') }

      it "builds and sends the report" do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return(true)
        allow(YAML).to receive(:safe_load).and_return(login)
        allow(Net::SFTP).to receive(:start).and_yield(sftp)
        allow(sftp).to receive(:upload!).and_return(true)

        described_class.perform_now(press.subdomain, "2022-02-14", "2022-06-11")

        expect(Net::SFTP).to have_received(:start)
        expect(sftp).to have_received(:upload!).with(file_path, remote_file_path)
      end
    end
  end

  describe "#build_report" do
    let(:red) do
      ::SolrDocument.new(id: 'red',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['_Red_'],
                         creator_tesim: ['An Author'],
                         publisher_tesim: ["R Pub"],
                         isbn_tesim: ['111', '222'],
                         date_created_tesim: ['2000'])
    end
    let(:a) do
      ::SolrDocument.new(id: 'a',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['A _FileSet_ Title'],
                         monograph_id_ssim: ['red'],
                         doi_ssim: ['10/something'])
    end
    let(:blue) do
      ::SolrDocument.new(id: 'blue',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['Blue, A Book'],
                         creator_tesim: ['Another Author', 'Third Author'],
                         publisher_tesim: ["B Pub"],
                         isbn_tesim: ['ZZZ', 'YYY'],
                         date_created_tesim: ['1999'],
                         open_access_tesim: ['yes'])
    end
    let(:b) do
      ::SolrDocument.new(id: 'b',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['B'],
                         monograph_id_ssim: ['blue'])
    end

    before do
      ActiveFedora::SolrService.add([red.to_h, a.to_h, blue.to_h, b.to_h])
      ActiveFedora::SolrService.commit

      FeaturedRepresentative.create(file_set_id: 'a', work_id: 'red', kind: 'epub')
      FeaturedRepresentative.create(file_set_id: 'b', work_id: 'blue', kind: 'pdf_ebook')

      create(:counter_report, press: press.id, session: "10.0.0.1|something|1",  noid: 'a', model: 'FileSet', parent_noid: 'red',  institution: 1, created_at: Time.zone.parse("2018-01-02"), access_type: "Controlled", request: 1)
      create(:counter_report, press: press.id, session: "10.0.0.2|something|1",  noid: 'b', model: 'FileSet', parent_noid: 'blue', institution: 1, created_at: Time.zone.parse("2018-01-10"), access_type: "Controlled", request: 1, section: "Chapter R", section_type: "Chapter")
      create(:counter_report, press: press.id, session: "10.0.0.3|something|1",  noid: 'b', model: 'FileSet', parent_noid: 'blue', institution: 1, created_at: Time.zone.parse("2018-01-22"), access_type: "Controlled", request: 1, section: "Chapter X", section_type: "Chapter")
    end

    it "builds the csv report" do
      travel_to(Time.zone.parse("2018-02-01")) do
        report = described_class.new.build_report(press, PsiReport::ReportTime.new)
        csv = CSV.new(report)
        rows = csv.read
        expect(rows[0]).to eq ["Event Date", "Event", "ISBN/DOI", "Publisher Name", "Book Title/Journal Title", "Author(s)", "Chapter/Article Title", "IP Adress", "OA/Paid", "Journal Imprint", "Orcid ID", "Affiliation", "Funders"]
        expect(rows[1]).to eq ["2018-01-02 00:00:00", "request", "https://doi.org/10/something", "R Pub", "Red", "An Author", "A FileSet Title", "10.0.0.1", "FALSE", "R Pub", "", "", ""]
        expect(rows[2]).to eq ["2018-01-10 00:00:00", "request", "ZZZ; YYY", "B Pub", "Blue, A Book", "Another Author;Third Author", "Chapter R", "10.0.0.2", "TRUE", "B Pub", "", "", ""]
        expect(rows[3]).to eq ["2018-01-22 00:00:00", "request", "ZZZ; YYY", "B Pub", "Blue, A Book", "Another Author;Third Author", "Chapter X", "10.0.0.3", "TRUE", "B Pub", "", "", ""]
      end
    end
  end

  describe "orcids" do
    let(:presenter) { Hyrax::PresenterFactory.build_for(ids: ['999999999'], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first }

    before do
      ActiveFedora::SolrService.add([monograph.to_h])
      ActiveFedora::SolrService.commit
    end

    context "all authors have orcids" do
      let(:monograph) do
        ::SolrDocument.new(id: '999999999',
                          has_model_ssim: ['Monograph'],
                          title_tesim: ['Red'],
                          creator_tesim: ['Moose, Bullwinkle', 'Squirrel, Rocky'],
                          creator_orcids_ssim: ['https://orcid.org/1', 'https://orcid.org/2'])
      end

      describe "#creators" do
        it "returns the authors in order" do
          expect(described_class.new.creators(presenter)).to eq "Moose, Bullwinkle;Squirrel, Rocky"
        end
      end

      describe "#orcids" do
        it "returns the orcids in order" do
          expect(described_class.new.orcids(presenter)).to eq "https://orcid.org/1;https://orcid.org/2"
        end
      end
    end

    context "some authors have orcids" do
      let(:monograph) do
        ::SolrDocument.new(id: '999999999',
                          has_model_ssim: ['Monograph'],
                          title_tesim: ['Red'],
                          creator_tesim: ['Moose, Bullwinkle',
                                          'Squirrel, Rocky',
                                          'Badenov, Boris',
                                          'Fatale, Natasha'],
                          creator_orcids_ssim: ["",
                                                "",
                                                "https://orcid.org/0000-0002-1825-0097",
                                                ""])
      end

      describe "#creators" do
        it "returns the authors in order" do
          expect(described_class.new.creators(presenter)).to eq "Moose, Bullwinkle;Squirrel, Rocky;Badenov, Boris;Fatale, Natasha"
        end
      end

      describe "#orcids" do
        it "returns the orcids in order with blanks for authors without orcids" do
          expect(described_class.new.orcids(presenter)).to eq ";;https://orcid.org/0000-0002-1825-0097;"
        end
      end
    end

    context "no authors have orcids" do
      let(:monograph) do
        ::SolrDocument.new(id: '999999999',
                          has_model_ssim: ['Monograph'],
                          title_tesim: ['Red'],
                          creator_tesim: ['Moose, Bullwinkle',
                                          'Squirrel, Rocky',
                                          'Badenov, Boris',
                                          'Fatale, Natasha'])
      end

      describe "#creators" do
        it "returns the authors" do
          expect(described_class.new.creators(presenter)).to eq "Moose, Bullwinkle;Squirrel, Rocky;Badenov, Boris;Fatale, Natasha"
        end
      end

      describe "#orcids" do
        it "returns nothing" do
          expect(described_class.new.orcids(presenter)).to eq ""
        end
      end
    end
  end
end
