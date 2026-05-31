require 'spec_helper'
require 'support/file_set_helper'

describe Hydra::Works::CharacterizationService do
  describe "integration test for characterizing from path on disk." do
    let(:filename)     { 'sample-file.pdf' }
    let(:path_on_disk) { File.join(fixture_path, filename) }
    let(:file)         { Hydra::PCDM::File.new }

    before do
      skip 'external tools not installed for CI environment' if ENV['CI']
      described_class.run(file, path_on_disk)
    end

    it 'successfully sets the property values' do
      expect(file.file_size).to eq(["7618"])
      expect(file.file_title).to eq(["sample-file"])
      expect(file.page_count).to eq(["1"])
      # Persist our file with some content and reload
      file.content = "junk"
      expect(file.save).to be true
      expect(file.reload).to be_empty
      # Re-check property values
      expect(file.file_size).to eq(["7618"])
      expect(file.file_title).to eq(["sample-file"])
      expect(file.page_count).to eq(["1"])
    end
  end

  describe "handling strings, files, and Hydra::PCDM::File as sources" do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization)   { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:fits_filename)      { 'fits_0.8.5_pdf.xml' }
    let(:fits_response)      { IO.read(File.join(fixture_path, fits_filename)) }
    let(:filename)           { 'sample-file.pdf' }
    let(:file_content)       { IO.read(File.join(fixture_path, filename)) }
    let(:file)               { Hydra::PCDM::File.new { |f| f.content = file_content } }

    before do
      allow(characterization).to receive(:characterize).and_return(fits_response)
    end

    context "with the object as the source" do
      it 'calls the content method of the object.' do
        expect(file).to receive(:content)
        described_class.run(file)
      end

      context "when original_name is not present" do
        it 'passes the content to characterization.' do
          expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, "original_file", :fits)
          described_class.run(file)
        end
      end

      context "when original_name is present" do
        before { allow(file).to receive(:original_name).and_return(filename) }
        it 'passes the content to characterization.' do
          expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, filename, :fits)
          described_class.run(file)
        end
      end
    end

    context "using a string path as the source." do
      it 'passes a file with the string as a path to FileCharacterization.' do
        path_on_disk = File.join(fixture_path, filename)
        expect(Hydra::FileCharacterization).to receive(:characterize).with(kind_of(File), filename, :fits)
        described_class.run(file, path_on_disk)
      end
    end

    context "using a File instance as the source." do
      it 'passes the File to FileCharacterization.' do
        file_inst = File.new(File.join(fixture_path, filename))
        expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, filename, :fits)
        expect(file_inst).to receive(:rewind)
        described_class.run(file, file_inst)
      end
    end
  end

  context "passing an object that does not have matching properties" do
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:fits_filename)    { 'fits_0.8.5_pdf.xml' }
    let(:fits_response)    { IO.read(File.join(fixture_path, fits_filename)) }
    let(:file_content)     { 'dummy content' }
    let(:file)             { Hydra::PCDM::File.new { |f| f.content = file_content } }

    around do |example|
      @current_schemas = ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas
      @metadata_schema = Hydra::PCDM::File::GeneratedMetadataSchema
      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas = [ActiveFedora::WithMetadata::DefaultSchema]
      example.run
      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas = @current_schemas
      # This next line required to force resetting the metadata schema class used by Hydra::PCDM::File
      Hydra::PCDM::File.instance_variable_set(:@metadata_schema, @metadata_schema)
    end

    before do
      allow(characterization).to receive(:characterize).and_return(fits_response)
    end

    it 'does not explode with an error' do
      expect { described_class.run(file) }.not_to raise_error
    end
  end

  describe 'assigned properties.' do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:file)             { Hydra::PCDM::File.new }

    before do
      allow(file).to receive(:content).and_return("mocked content")
      allow(characterization).to receive(:characterize).and_return(fits_response)
      described_class.run(file)
    end

    context 'using document metadata' do
      let(:fits_filename) { 'fits_0.8.5_pdf.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'assigns expected values to document properties.' do
        expect(file.file_title).to eq(["sample-file"])
        expect(file.page_count).to eq(["1"])
      end
    end

    context 'using netCDF metadata' do
      let(:fits_filename) { 'fits_netcdf_two_mimetypes.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'reports the correct, single MIME type' do
        expect(file.mime_type).to eq("application/netcdf")
      end
    end

    context 'using image metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_0.8.5' do
        let(:fits_filename) { 'fits_0.8.5_jp2.xml' }
        it 'assigns expected values to image properties.' do
          expect(file.file_size).to eq(["11043"])
          expect(file.byte_order).to eq(["big endian"])
          expect(file.compression).to contain_exactly("JPEG 2000 Lossless", "JPEG 2000")
          expect(file.width).to eq(["512"])
          expect(file.height).to eq(["465"])
          expect(file.color_space).to eq(["sRGB"])
        end
      end

      context 'with fits_1.2.0' do
        let(:fits_filename) { 'fits_1.2.0_jpg.xml' }
        it 'ensures duplicate values are not returned for exifVersion, dateCreated, dateModified.' do
          expect(file.exif_version).to eq(["0221"])
          expect(file.date_created).to eq(["2009:02:04 11:05:25.36-06:00"])
          expect(file.date_modified).to eq(["2009:02:04 16:10:47"])
        end
      end
    end

    context 'using video metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_0.8.5' do
        let(:fits_filename) { 'fits_0.8.5_avi.xml' }
        it 'assigns expected values to video properties.' do
          expect(file.height).to eq(["264"])
          expect(file.width).to eq(["356"])
          expect(file.duration).to eq(["14.10 s"])
          expect(file.frame_rate).to eq(["10"])
          expect(file.sample_rate).to eq(["11025"])
        end
      end

      context 'with fits_1.2.0' do
        let(:fits_filename) { 'fits_1.2.0_avi.xml' }
        it 'assigns expected values to video properties.' do
          expect(file.height).to eq(["264"])
          expect(file.width).to eq(["356"])
          expect(file.duration).to eq(["14148"])
          expect(file.frame_rate).to eq(["10.000"])
          expect(file.bit_rate).to eq(["409204"])
          expect(file.aspect_ratio).to eq(["4:3"])
        end
      end
    end

    context 'using audio metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_0.8.5' do
        let(:fits_filename) { 'fits_0.8.5_mp3.xml' }
        it 'assigns expected values to audio properties.' do
          expect(file.mime_type).to eq("audio/mpeg")
          expect(file.duration).to eq(["0:0:15:261"])
          expect(file.bit_rate).to include("192000")
          expect(file.sample_rate).to eq(["44100"])
        end
      end

      context 'with fits_1.2.0' do
        let(:fits_filename) { 'fits_1.2.0_mp3.xml' }
        it 'assigns expected values to audio properties.' do
          expect(file.mime_type).to eq("audio/mpeg")
          expect(file.duration).to eq(["0:0:15:261"])
          expect(file.bit_rate).to include("192000")
          expect(file.sample_rate).to eq(["44100"])
        end
      end
    end

    context 'using multi-layer tiff metadata' do
      let(:fits_filename) { 'fits_0.8.5_tiff.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'assigns single largest value to width, height' do
        expect(file.width).to eq(["2226"])
        expect(file.height).to eq(["1650"])
      end
    end
  end

  describe 'assigned properties from fits 0.6.2' do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:file)             { Hydra::PCDM::File.new }

    context 'using image metadata' do
      let(:fits_filename) { 'fits_0.6.2_jpg.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }
      before do
        allow(file).to receive(:content).and_return("mocked content")
        allow(characterization).to receive(:characterize).and_return(fits_response)
        described_class.run(file)
      end
      it 'assigns expected values to image properties.' do
        expect(file.file_size).to eq(["57639"])
        expect(file.byte_order).to eq(["big endian"])
        expect(file.compression).to eq(["JPEG (old-style)"])
        expect(file.width).to eq(["600"])
        expect(file.height).to eq(["381"])
        expect(file.color_space).to eq(["YCbCr"])
      end
    end
  end
end
