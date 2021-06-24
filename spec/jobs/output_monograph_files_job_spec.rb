# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OutputMonographFilesJob, type: :job do
  describe "perform" do
    let(:monograph) { create(:monograph) }
    let(:file_set1) { create(:file_set, title: [file_1_original_name]) }
    let(:file_set2) { create(:file_set, title: [file_2_original_name]) }
    let(:path) { Rails.root.join('tmp', 'spec', 'rspec_output_monograph_files_job') }
    let(:file_1_original_name) { 'kitty.tif' }
    let(:file_2_original_name) { "ファイル.txt" }

    let(:original_file) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'kitty.tif'))
        f.original_name = file_1_original_name
        f.file_size = File.size(File.join(fixture_path, 'kitty.tif'))
      end
    end

    let(:original_file_non_ascii) do
      Hydra::PCDM::File.new do |f|
        f.content = File.open(File.join(fixture_path, 'csv', 'import_sections', file_2_original_name))
        f.original_name = file_2_original_name
        f.file_size = File.size(File.join(fixture_path, 'csv', 'import_sections', file_2_original_name))
      end
    end

    before do
      file_set1.original_file = original_file
      file_set1.save!

      # Upgrading to ruby 2.7.3 made this spec weird, HELIO-3950
      # Not sure why, but this gets it to pass.
      # Works fine in dev, not sure why the spec needs this.
      file_set2.original_file = original_file_non_ascii
      file_set2.save!
      file_set2.original_file.original_name.force_encoding("UTF-8")
      file_set2.save!

      monograph.ordered_members << file_set1
      monograph.ordered_members << file_set2
      monograph.save!
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
    end

    it "deletes any AF objects whose NOIDs are passed in" do
      described_class.perform_now(monograph.id, path)
      expect(Dir.glob(File.join(path, '**', '*')).select { |file| File.file?(file) }.count).to be 2
      expect(File.exist?(File.join(path, file_1_original_name))).to be true
      expect(File.exist?(File.join(path, file_2_original_name))).to be true
    end
  end
end
