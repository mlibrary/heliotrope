# frozen_string_literal: true

require 'rails_helper'
require 'import/csv_parser'
require 'metadata_fields' unless defined?(MONO_FILENAME_FLAG) # solves loading issue when this spec is run solo

describe Import::CSVParser do
  let(:input_file) { File.join(fixture_path, 'csv', 'import_sections', 'tempest_sections.csv') }
  let(:parser) { described_class.new(input_file) }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe 'initializer' do
    it 'has an input file' do
      expect(parser.file).to eq input_file
    end
  end

  describe '#attributes' do
    subject { parser.attributes }

    it 'collects attributes from the CSV file' do
      expect(subject['title']).to eq ['The Tempest: A Subtitle']
      # testing aggregation of identifiers such as legacy handle and ID here
      expect(subject['identifier']).to eq ['http://www.example.com/handle', '999.999.9999']
      expect(subject['creator']).to eq ["Shakespeare, William\nPlaywright, Mr. Uncredited"]
      expect(subject['contributor']).to eq ["Christopher Marlowe\nSir Francis Bacon"]
      expect(subject['subject']).to eq ['Dog', 'Cat', 'Mouse']
      expect(subject['isbn']).to eq ['134513451345', '1451-25423', '1451343513']
      expect(subject['series']).to eq ['Series the First', 'Cereal Series', 'Serial the Third']
      expect(subject['files']).to eq [
        'shipwreck.jpg',
        'miranda.jpg',
        'ファイル.txt',
        'shipwreck1.jpg',
        'miranda1.jpg',
        'shipwreck2.jpg',
        'miranda2.jpg',
        'shipwreck1.jpg',
        nil
      ]

      expect(subject['files_metadata'].count).to eq 9

      expect(subject['files_metadata']).to eq [
        { 'title' => ['Monograph Shipwreck'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Attribution-ShareAlike license, 3.0 Unported',
          'exclusive_to_platform' => 'no',
          'content_type' => ['portrait'],
          'creator' => ['Smith, Benjamin'],
          'language' => ['English'] },
        { 'title' => ['Monograph Miranda'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['audience materials'],
          'creator' => ['Waterhouse, John William'],
          'language' => ['English', 'German'] },
        { 'title' => ['日本語のファイル'],
          'resource_type' => ['text'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['portrait', 'illustration'],
          'language' => ['Japanese'] },
        { 'title' => ['Section 1 Shipwreck'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['audience materials'],
          'creator' => ['Smith'],
          'keywords' => ['keyword1', 'keyword2'],
          'section_title' => ['Act 1: Calm Waters'],
          'language' => ['Russian'] },
        { 'title' => ['Section 1 Miranda'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['portrait'],
          'creator' => ["Waterhouse, John William\nCreator, A. Second"],
          'keywords' => ['regular', 'italicized'],
          'section_title' => ['Act 1: Calm Waters'],
          'language' => ['Russian', 'German', 'French'] },
        { 'title' => ['Section 2 Shipwreck'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['audience materials'],
          'creator' => ['Smith'],
          'section_title' => ['Act 2: Stirrin\' Up'],
          'language' => ['French'] },
        { 'title' => ['Section 2 Miranda'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['illustration'],
          'creator' => ['Waterhouse, John William'],
          'section_title' => ['Act 2: Stirrin\' Up'],
          'language' => ['English'] },
        { 'title' => ['Previous Shipwreck File (Again)'],
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'exclusive_to_platform' => 'yes',
          'content_type' => ['portrait', 'photograph'],
          'creator' => ['Smith'],
          'section_title' => ['Act 2: Stirrin\' Up'],
          'language' => ['Latin'] },
        { 'title' => ['External Bard Transcript'],
          'resource_type' => ['text'],
          'external_resource' => 'yes',
          'exclusive_to_platform' => 'no',
          'content_type' => ['Interview Transcript'],
          'creator' => ['L\'Interviewere, Bob'],
          'keywords' => ['interview'],
          'section_title' => ['Act 3: External Stuffs'],
          'language' => ['English'] }
      ]
    end
  end
end
