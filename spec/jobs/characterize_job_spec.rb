# frozen_string_literal: true

require 'rails_helper'
require 'fakefs/spec_helpers'

# Since we lifted this out of CC 1.6.2, we'll need to run the tests too

describe CharacterizeJob do
  let(:file_set) { FileSet.new(id: file_set_id, title: ['previous_file.jpg'], label: 'previous_file.jpg', date_modified: 'previous_mod_date', resource_type: [resource_type]) }
  let(:resource_type) { 'resource_type' }
  let(:file_set_id) { 'abc12345' }
  let(:file_path)   { Rails.root + 'tmp' + 'uploads' + 'ab' + 'c1' + '23' + '45' + 'abc12345' + 'picture.png' }
  let(:filename)    { file_path.to_s }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.height = '111'
      f.width = '222'
      f.file_size = '123456'
      f.format_label = ["Portable Network Graphics"]
      f.original_checksum = ['asdf123456']
      f.save!
    end
  end

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    allow(file_set).to receive(:original_file).and_return(file)
  end

  context 'when the characterization proxy content is present' do
    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      expect(file).to receive(:save!)
      expect(file_set).to receive(:update_index)
      expect(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      described_class.perform_now(file_set, file.id)
    end
  end

  context 'when the characterization proxy content is absent' do
    before { allow(file_set).to receive(:characterization_proxy?).and_return(false) }

    it 'raises an error' do
      expect { described_class.perform_now(file_set, file.id) }.to raise_error(LoadError, 'original_file was not found')
    end
  end

  context "when the file set's work is in a collection" do
    let(:work)       { build(:monograph) }
    let(:collection) { build(:collection) }

    before do
      allow(file_set).to receive(:parent).and_return(work)
      allow(work).to receive(:in_collections).and_return([collection])
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      allow(file).to receive(:save!)
      allow(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
    end

    it "reindexes the collection" do
      expect(collection).to receive(:update_index)
      described_class.perform_now(file_set, file.id)
    end
  end

  context "FileSet with unwanted, preexisting characterization metadata getting new version" do
    it "resets the height and width" do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      expect(file).to receive(:save!)
      expect(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      allow(file_set).to receive(:original_checksum).and_return(['qwerty789'])
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return('Tue, 10 Apr 2019 20:20:20 +0000')
      described_class.perform_now(file_set, file.id)

      expect(file_set.original_file.height).to eq []
      expect(file_set.original_file.width).to eq []
      expect(file_set.original_file.original_checksum).to eq []
      expect(file_set.original_file.file_size).to eq []
      expect(file_set.original_file.format_label).to eq []
      expect(file_set.label).to eq 'picture.png'
      expect(file_set.title).to eq ['picture.png']
      expect(file_set.date_modified).to eq 'Tue, 10 Apr 2019 20:20:20 +0000'
    end
  end

  context "when there's a preexisting IIIF cached file" do
    include FakeFS::SpecHelpers
    let(:cached_file) { Rails.root.join('tmp', 'network_files', Digest::MD5.hexdigest(file_set.original_file.uri.to_s)) }

    it "deletes the cached file" do
      FileUtils.mkdir_p Rails.root.join('tmp', 'network_files')
      FileUtils.touch cached_file
      expect(cached_file.exist?).to be true

      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      allow(file).to receive(:save!)
      allow(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      described_class.perform_now(file_set, file.id)

      expect(cached_file.exist?).to be false
    end
  end

  context "featured representative" do
    let(:file_path) { Rails.root + 'tmp' + 'uploads' + 'ab' + 'c1' + '23' + '45' + 'abc12345' + file_type }
    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = file_type
        f.save!
      end
    end
    let(:monograph) { build(:monograph, id: 'mono_id', press: 'press') }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      allow(file).to receive(:save!)
      allow(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      allow(file_set).to receive(:parent).and_return(monograph)
    end

    after { FeaturedRepresentative.destroy_all }

    FeaturedRepresentative::KINDS.each do |kind|
      context kind.to_s do
        let(:file_type) { "file.#{kind}" }

        before { allow(UnpackJob).to receive(:perform_later).and_return(true) }

        it "unpacks some kinds" do
          create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: kind)
          described_class.perform_now(file_set, file.id)
          case kind
          when 'epub', 'webgl', 'pdf_ebook'
            expect(UnpackJob).to have_received(:perform_later).with(file_set.id, kind)
          else
            expect(UnpackJob).not_to have_received(:perform_later).with(file_set.id, kind)
          end
        end
      end
    end
  end

  context 'resource type' do
    let(:file_path) { Rails.root + 'tmp' + 'uploads' + 'ab' + 'c1' + '23' + '45' + 'abc12345' + file_type }
    let(:file_type) { 'file.zip' }
    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = file_type
        f.save!
      end
    end
    let(:monograph) { build(:monograph, id: 'mono_id', press: 'press') }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      allow(file).to receive(:save!)
      allow(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      allow(file_set).to receive(:parent).and_return(monograph)
    end

    %w[interactive\ map map foo].each do |resource_type|
      context resource_type do
        let(:resource_type) { resource_type }

        before { allow(UnpackJob).to receive(:perform_later).and_return(true) }

        it "unpacks some resource types" do
          described_class.perform_now(file_set, file.id)
          case resource_type
          when 'interactive_map'
            expect(UnpackJob).to have_received(:perform_later).with(file_set.id, resource_type)
          when 'map'
            expect(UnpackJob).not_to have_received(:perform_later).with(file_set.id, resource_type)
          else
            expect(UnpackJob).not_to have_received(:perform_later).with(file_set.id, resource_type)
          end
        end
      end
    end
  end
end
