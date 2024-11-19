# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarcIngestJob, type: :job do
  describe "#perform" do
    let(:sftp) { instance_double(Marc::Sftp) }

    context "with a new, valid, ~/marc_ingest file from Alma" do
      let(:file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz").to_s }
      let(:files) { [file] }
      let(:doc) { SolrDocument.new(id: "999999999", press_tesim: ["michigan"], doi_ssim: ["10.3998/mpub.12527012"]) }
      let(:marc_xml_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "999999999.xml").to_s }
      let(:product_dir) { "/home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC" }
      let(:mailer) { double("mailer", deliver_now: true) }
      let(:report) { ["SUCCESS\tumpebc 999999999 999999999.xml moved to /home/fulcrum_ftp/MARC_from_Cataloging/UMPEBC"] }

      before do
        FileUtils.mkdir_p(File.join(Settings.scratch_space_path, "marc_processing"))
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.tar.gz").to_s, file)
        ActiveFedora::SolrService.add(doc.to_h)
        ActiveFedora::SolrService.commit
        allow(Marc::Sftp).to receive(:new).and_return(sftp)
        allow(sftp).to receive(:download_marc_ingest_files).and_return(files)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_product_dir).with(marc_xml_file, product_dir).and_return(true)
        allow(sftp).to receive(:remove_marc_ingest_file).with(file).and_return(true)
        allow(MarcIngestMailer).to receive(:send_mail).with(report).and_return(mailer)
      end

      it "puts the created single marc file in the correct remote directory and sends an email" do
        described_class.perform_now

        expect(sftp).to have_received(:upload_local_marc_file_to_remote_product_dir).with(marc_xml_file, product_dir)
        expect(sftp).to have_received(:remove_marc_ingest_file).with(file)
        expect(MarcIngestMailer).to have_received(:send_mail).with(report)
      end
    end

    # Every night Alma sends a file regardless of if it has any records in it.
    context "with an empty alma file" do
      let(:file) { Rails.root.join("tmp", "marc_processing", "empty_file_from_alma.tar.gz").to_s }
      let(:files) { [file] }
      let(:mailer) { double("mailer", deliver_now: true) }
      let(:report) { [] }

      before do
        allow(Marc::Sftp).to receive(:new).and_return(sftp)
        allow(sftp).to receive(:download_marc_ingest_files).and_return(files)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_product_dir)
        allow(sftp).to receive(:remove_marc_ingest_file)
        allow(MarcIngestMailer).to receive(:send_mail).with(report).and_return(mailer)
        allow(MarcLogger).to receive(:info)
      end

      it "logs the job, does not send mail" do
        described_class.perform_now
        expect(MarcLogger).to have_received(:info).with("Beginning MarcIngestJob...").once
        expect(MarcLogger).to have_received(:info).with("1 files found in /marc_ingest").once
        expect(MarcLogger).to have_received(:info).with("No MARC records found in files: #{file}").once
        expect(MarcLogger).to have_received(:info).with("MarcIngestJob finished").once
        expect(MarcIngestMailer).not_to have_received(:send_mail)
      end
    end

    context "with an invalid marc file (missing 003 field)" do
      let(:file) { Rails.root.join("tmp", "marc_processing", "003_missing.tar.gz").to_s }
      let(:files) { [file] }
      let(:doc) { SolrDocument.new(id: "999999999", press_tesim: ["leverpress"], doi_ssim: ["10.3998/mpub.10209707"]) }
      let(:marc_xml_file) { Rails.root.join("tmp", "marc_processing", "003_missing", "003_missing_00001.xml").to_s }
      let(:mailer) { double("mailer", deliver_now: true) }
      let(:report) { ["ERROR\tleverpress 999999999 003_missing_00001.xml has no 003 field"] }

      before do
        FileUtils.mkdir_p(File.join(Settings.scratch_space_path, "marc_processing"))
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "003_missing.tar.gz").to_s, file)
        ActiveFedora::SolrService.add(doc.to_h)
        ActiveFedora::SolrService.commit
        allow(Marc::Sftp).to receive(:new).and_return(sftp)
        allow(sftp).to receive(:download_marc_ingest_files).and_return(files)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_failures).with(marc_xml_file).and_return(true)
        allow(sftp).to receive(:remove_marc_ingest_file).with(file).and_return(true)
        allow(MarcIngestMailer).to receive(:send_mail).with(report).and_return(mailer)
        allow(MarcLogger).to receive(:info)
      end

      it "moves the file to the /failures dir and sends an email" do
        described_class.perform_now
        expect(sftp).to have_received(:upload_local_marc_file_to_remote_failures).with(marc_xml_file)
        expect(MarcIngestMailer).to have_received(:send_mail).with(report)
      end
    end

    context "a valid marc record but that has no group_key (yet) in Marc::DirectoryMapper" do
      let(:file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz").to_s }
      let(:files) { [file] }
      let(:doc) { SolrDocument.new(id: "999999999", press_tesim: ["a_brand_new_press"], doi_ssim: ["10.3998/mpub.12527012"]) }
      let(:marc_xml_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma_00001.xml").to_s }
      let(:mailer) { double("mailer", deliver_now: true) }
      let(:report) { ["ERROR\tMarc::DirectoryMapper is missing a group_key for '#{marc_xml_file}'!"] }

      before do
        FileUtils.mkdir_p(File.join(Settings.scratch_space_path, "marc_processing"))
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.tar.gz").to_s, file)
        ActiveFedora::SolrService.add(doc.to_h)
        ActiveFedora::SolrService.commit
        allow(Marc::Sftp).to receive(:new).and_return(sftp)
        allow(sftp).to receive(:download_marc_ingest_files).and_return(files)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_product_dir)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_failures)
        allow(sftp).to receive(:remove_marc_ingest_file).with(file).and_return(true)
        allow(MarcIngestMailer).to receive(:send_mail).with(report).and_return(mailer)
      end

      it "sends an email with the error, does not move the file" do
        described_class.perform_now
        expect(sftp).not_to have_received(:upload_local_marc_file_to_remote_product_dir)
        expect(sftp).not_to have_received(:upload_local_marc_file_to_remote_failures)
        expect(MarcIngestMailer).to have_received(:send_mail).with(report)
      end
    end

    context "with a marc file that has no matching monograph in fulcrum (yet)" do
      let(:file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz").to_s }
      let(:files) { [file] }
      let(:doc) { SolrDocument.new(id: "999999999", press_tesim: ["leverpress"], doi_ssim: ["10.3998/mpub.NOT_A_REGISTERED_DOI"]) }
      let(:marc_xml_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma_00001.xml").to_s }
      let(:mailer) { double("mailer", deliver_now: true) }
      let(:report) { ["ERROR\tsingle_record_from_alma_00001.xml does not have a DOI or Handle that is in fulcrum, 024$a value is '10.3998/mpub.12527012'"] }

      before do
        FileUtils.mkdir_p(File.join(Settings.scratch_space_path, "marc_processing"))
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.tar.gz").to_s, file)
        ActiveFedora::SolrService.add(doc.to_h)
        ActiveFedora::SolrService.commit
        allow(Marc::Sftp).to receive(:new).and_return(sftp)
        allow(sftp).to receive(:download_marc_ingest_files).and_return(files)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_product_dir)
        allow(sftp).to receive(:upload_local_marc_file_to_remote_failures).with(marc_xml_file).and_return(true)
        allow(sftp).to receive(:remove_marc_ingest_file).with(file).and_return(true)
        allow(MarcIngestMailer).to receive(:send_mail).with(report).and_return(mailer)
        allow(MarcLogger).to receive(:info)
      end

      it "considers the record 'invalid' based on no DOI/Handle match so moves it to /failures and sends an email" do
        described_class.perform_now
        expect(sftp).not_to have_received(:upload_local_marc_file_to_remote_product_dir)
        expect(sftp).to have_received(:upload_local_marc_file_to_remote_failures).with(marc_xml_file)
        expect(MarcIngestMailer).to have_received(:send_mail).with(report)
      end
    end
  end
end
