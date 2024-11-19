# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Marc::LocalFileHandler do
  describe "#clean_up_processing_dir" do
    # Simple but destructive. Call at the very end of all processing
    it "cleans up the marc_processing directory" do
      fh = described_class.new
      FileUtils.touch(File.join(fh.processing_dir, "test1.txt"))
      FileUtils.touch(File.join(fh.processing_dir, "test2.txt"))
      FileUtils.mkdir(File.join(fh.processing_dir, "test"))
      FileUtils.touch(File.join(fh.processing_dir, "test", "test3.txt"))

      fh.clean_up_processing_dir
      expect(Dir[File.join(fh.processing_dir, "*")].empty?).to be true
    end
  end

  describe "#convert_to_individual_marc_files" do
    # Given local Alma generated file(s) downloaded from ftp.fulcrum.org/marc_ingest
    # Convert them to individual marc files to be validated and moved to the correct product directories
    let(:files) {
      [
        Rails.root.join("tmp", "marc_processing", "3_records_from_alma.tar.gz").to_s,
        Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz").to_s,
        Rails.root.join("tmp", "marc_processing", "empty_file_from_alma.tar.gz").to_s
      ]
    }

    before do
      FileUtils.mkdir_p File.join(Settings.scratch_space_path, "marc_processing")
      FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "3_records_from_alma.tar.gz"),
                   Rails.root.join("tmp", "marc_processing", "3_records_from_alma.tar.gz"))
      FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.tar.gz"),
                   Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz"))
      FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "empty_file_from_alma.tar.gz"),
                   Rails.root.join("tmp", "marc_processing", "empty_file_from_alma.tar.gz"))
    end

    after do
      described_class.new.clean_up_processing_dir
    end

    it "converts tar gzipped Alma files with 0 or more records into seperate single record marc files" do
      fh = described_class.new
      # byebug
      marc_files = fh.convert_to_individual_marc_files(files)
      expect(marc_files.count).to eq 4
      # They have the correct names
      expect(marc_files[0]).to eq Rails.root.join("tmp", "marc_processing", "3_records_from_alma", "3_records_from_alma_00001.xml").to_s
      expect(marc_files[1]).to eq Rails.root.join("tmp", "marc_processing", "3_records_from_alma", "3_records_from_alma_00002.xml").to_s
      expect(marc_files[2]).to eq Rails.root.join("tmp", "marc_processing", "3_records_from_alma", "3_records_from_alma_00003.xml").to_s
      expect(marc_files[3]).to eq Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma_00001.xml").to_s
      # They are readable MARC files
      expect(MARC::XMLReader.new(marc_files[0]).first["001"].value).to eq "99188092514106381"
      expect(MARC::XMLReader.new(marc_files[1]).first["001"].value).to eq "99188092514006381"
      expect(MARC::XMLReader.new(marc_files[2]).first["001"].value).to eq "99188091309306381"
      expect(MARC::XMLReader.new(marc_files[3]).first["001"].value).to eq "10.3998/mpub.12527012"
    end
  end

  describe "#ungzip_untar" do
    let(:test_file) { Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.tar.gz").to_s }
    let(:archived_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma.tar.gz").to_s }
    let(:unpacked_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma.xml").to_s }

    before do
      FileUtils.cp(test_file, archived_file)
    end

    after do
      described_class.new.clean_up_processing_dir
    end

    it "ungzips and untars the archive, then cleans it all up" do
      fh = described_class.new
      expect(File.exist?(archived_file)).to be true
      fh.ungzip_untar(archived_file)
      expect(File.exist?(archived_file)).to be false
      expect(File.exist?(unpacked_file)).to be true
    end
  end

  describe "#split_marc" do
    context "with multiple marc records" do
      let(:alma_dir) { Rails.root.join("tmp", "marc_processing", "3_records_from_alma") }

      before do
        FileUtils.mkdir_p alma_dir
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "3_records_from_alma.xml"),
                     Rails.root.join("tmp", "marc_processing", "3_records_from_alma", "3_records_from_alma.xml"))
      end

      after do
        described_class.new.clean_up_processing_dir
      end

      it "creates the marc files" do
        fh = described_class.new
        marc_files = fh.split_marc(alma_dir)
        expect(marc_files.count).to eq 3
        # They have the correct names
        expect(marc_files[0]).to eq File.join(alma_dir, "3_records_from_alma_00001.xml")
        expect(marc_files[1]).to eq File.join(alma_dir, "3_records_from_alma_00002.xml")
        expect(marc_files[2]).to eq File.join(alma_dir, "3_records_from_alma_00003.xml")
        # They are readable MARC files
        expect(MARC::XMLReader.new(marc_files[0]).first["001"].value).to eq "99188092514106381"
        expect(MARC::XMLReader.new(marc_files[1]).first["001"].value).to eq "99188092514006381"
        expect(MARC::XMLReader.new(marc_files[2]).first["001"].value).to eq "99188091309306381"
      end
    end

    context "with a single marc record" do
      let(:alma_dir) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma") }

      before do
        FileUtils.mkdir_p alma_dir
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.xml"),
                     Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma.xml"))
      end

      after do
        described_class.new.clean_up_processing_dir
      end

      it "creates the marc file" do
        fh = described_class.new
        marc_files = fh.split_marc(alma_dir)
        expect(marc_files.count).to eq 1
        expect(marc_files[0]).to eq File.join(alma_dir, "single_record_from_alma_00001.xml")
        expect(MARC::XMLReader.new(marc_files[0]).first["001"].value).to eq "10.3998/mpub.12527012"
      end
    end

    context "with no marc records" do
      let(:alma_dir) { Rails.root.join("tmp", "marc_processing", "empty_file_from_alma") }

      before do
        FileUtils.mkdir_p alma_dir
        FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "empty_file_from_alma.xml"),
                     Rails.root.join("tmp", "marc_processing", "empty_file_from_alma", "empty_file_from_alma.xml"))
      end

      after do
        described_class.new.clean_up_processing_dir
      end

      it "returns no marc files" do
        fh = described_class.new
        marc_files = fh.split_marc(alma_dir)
        # Files from Alma that have no records aren't totally empty, they just have no records. They look like:
        # <collection></collection>
        expect(marc_files.count).to eq 0
      end
    end
  end

  describe "#rename_file_with_noid" do
    let(:validator) { instance_double(Marc::Validator) }
    let(:source_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "single_record_from_alma_000001.xml").to_s }
    let(:dest_file) { Rails.root.join("tmp", "marc_processing", "single_record_from_alma", "999999999.xml").to_s }

    before do
      FileUtils.mkdir_p(Rails.root.join("tmp", "marc_processing", "single_record_from_alma").to_s)
      FileUtils.cp(Rails.root.join("spec", "fixtures", "marc", "single_record_from_alma.xml").to_s, source_file)
      allow(validator).to receive(:noid).and_return("999999999")
      allow(validator).to receive(:file).and_return(source_file)
    end

    after do
      described_class.new.clean_up_processing_dir
    end

    it "renames the single marc file with the book's noid" do
      fh = described_class.new
      rvalue = fh.rename_file_with_noid(validator)
      expect(rvalue).to eq dest_file
      expect(File.exist?(source_file)).to be false
      expect(File.exist?(dest_file)).to be true
    end
  end
end
