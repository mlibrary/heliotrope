# frozen_string_literal: true

require 'rails_helper'

describe FileSetIndexer do
  describe "indexing a file_set" do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(file_set2) }
    let(:monograph) { create(:monograph) }
    let(:file_set1) { create(:file_set) }
    let(:file_set2) do
      create(:file_set,
             creator: ["Moose, Bullwinkle\nSquirrel, Rocky"],
             section_title: ['A section title'],
             description: ["This is the description"],
             extra_json_properties: { whatever_you_want: "Homer Simpson", score_version: "7" }.to_json)
    end
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
      monograph.ordered_members << file_set1 << file_set2
      monograph.save!
    end

    it "indexes all creators' names for access/search and faceting" do
      expect(subject['creator_tesim']).to eq ['Moose, Bullwinkle', 'Squirrel, Rocky'] # search
      expect(subject['creator_sim']).to eq ['Moose, Bullwinkle', 'Squirrel, Rocky'] # facet
    end

    it "indexes its section_title" do
      expect(subject['section_title_tesim']).to eq ['A section title']
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

    it "does not index this an an animated GIF" do
      expect(subject['animated_gif_ssi']).to eq nil
    end

    it "indexes its original_name" do
      expect(subject['original_name_tesim']).to eq file_set2.original_file.original_name
    end

    it "indexes its monograph's id" do
      expect(subject['monograph_id_ssim']).to eq monograph.id
    end

    it "indexes its position within the monograph" do
      expect(subject['monograph_position_isi']).to eq 1
    end

    it "reindexes its position when the monograph's ordered members change" do
      monograph.ordered_members = [file_set2, file_set1]
      monograph.save!
      expect(subject['monograph_position_isi']).to eq 0
    end

    it 'has description indexed by Hyrax::IndexesBasicMetadata' do
      expect(subject['description_tesim'].first).to eq 'This is the description'
    end

    it "indexes the extra_json_properties" do
      expect(subject['whatever_you_want_tesim']).to eq "Homer Simpson"
      expect(subject['score_version_tesim']).to eq "7"
    end
  end

  describe "indexing GIF file_sets" do
    subject { indexer.generate_solr_document }

    let(:indexer) { described_class.new(file_set) }
    let(:file_set) do
      create(:file_set)
    end

    before do
      stub_out_redis
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    end

    context 'GIF file without animation' do
      let(:file) { File.open(File.join(fixture_path, 'static.gif')) }

      it "does not index this as an animated GIF" do
        expect(subject['animated_gif_bsi']).to eq nil
      end
    end

    context 'GIF file with animation' do
      let(:file) { File.open(File.join(fixture_path, 'animated.gif')) }

      it "indexes this an an animated GIF" do
        expect(subject['animated_gif_bsi']).to eq true
      end
    end
  end
end
