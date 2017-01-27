require 'rails_helper'

describe FileSetIndexer do
  let(:indexer) { described_class.new(file_set2) }
  let(:monograph) { create(:monograph) }
  let(:section) { create(:section, monograph_id: monograph.id) }
  let(:file_set1) { create(:file_set) }
  let(:file_set2) { create(:file_set) }
  let(:file_set3) { create(:file_set) }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.sample_rate = 44
      f.duration = '12:01'
      f.original_checksum = '12345'
      f.save!
    end
  end

  before do
    allow(file_set2).to receive(:original_file).and_return(file)
    monograph.ordered_members << file_set1
    section.ordered_members << file_set2
    section.save!
    monograph.ordered_members << section
    monograph.ordered_members << file_set3
    monograph.save!
  end

  describe "indexing a file_set" do
    subject { indexer.generate_solr_document }

    it "indexes its section_title" do
      expect(subject['section_title_tesim']).to eq section.title
    end

    it "indexes its sample_rate" do
      expect(subject['sample_rate_ssim']).to eq file_set2.original_file.sample_rate
    end

    it "indexes its duration" do
      expect(subject['duration_ssim']).to eq file_set2.original_file.duration.first
    end

    it "indexes its original_checksum" do
      expect(subject['original_checksum_ssim']).to eq file_set2.original_file.original_checksum
    end

    it "indexs its original_name" do
      expect(subject['original_name_tesim']).to eq file_set2.original_file.original_name
    end

    it "indexes its monograph's id" do
      expect(subject['monograph_id_ssim']).to eq monograph.id
    end

    it "indexes its position within the monograph" do
      expect(subject['monograph_position_isi']).to eq 1
    end

    it "reindexes its position when the monograph's ordered members change" do
      monograph.ordered_members = [section, file_set2, file_set1]
      monograph.save!
      expect(subject['monograph_position_isi']).to eq 0
    end
  end
end
