require 'rails_helper'
require 'import/csv_parser'

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
      expect(subject['monograph']['title']).to eq ['The Tempest', 'A Subtitle']
      expect(subject['monograph']['creator_family_name']).to eq 'Shakespeare'
      expect(subject['monograph']['creator_given_name']).to eq 'William'
      expect(subject['monograph']['files']).to eq ['shipwreck.jpg', 'miranda.jpg', 'ファイル.txt']
      expect(subject['monograph']['files_metadata']).to eq [
        { 'title' => ['Monograph Shipwreck'],
          'creator_family_name' => 'Smith',
          'creator_given_name' => 'Benjamin',
          'resource_type' => ['image'] },
        { 'title' => ['Monograph Miranda'],
          'creator_family_name' => 'Waterhouse',
          'creator_given_name' => 'John William',
          'resource_type' => ['image'] },
        { 'title' => ['日本語のファイル'],
          'creator_family_name' => nil,
          'creator_given_name' => nil,
          'resource_type' => ['text'] }
      ]

      expect(subject['sections'])
        .to include('Act 1: Calm Waters' => { 'title' => ['Act 1: Calm Waters'],
                                              'files' => ['shipwreck1.jpg', 'miranda1.jpg'],
                                              'files_metadata' => [{ 'title' => ['Section 1 Shipwreck'], 'creator_family_name' => 'Smith', 'creator_given_name' => nil, 'resource_type' => ['image'] },
                                                                   { 'title' => ['Section 1 Miranda'], 'creator_family_name' => 'Waterhouse', 'creator_given_name' => 'John William', 'resource_type' => ['image'] }]
                                            })

      expect(subject['sections'])
        .to include('Act 2: Stirrin\' Up' => { 'title' => ['Act 2: Stirrin\' Up'],
                                               'files' => ['shipwreck2.jpg', 'miranda2.jpg', 'shipwreck1.jpg'],
                                               'files_metadata' => [{ 'title' => ['Section 2 Shipwreck'], 'creator_family_name' => 'Smith', 'creator_given_name' => nil, 'resource_type' => ['image'] },
                                                                    { 'title' => ['Section 2 Miranda'], 'creator_family_name' => 'Waterhouse', 'creator_given_name' => 'John William', 'resource_type' => ['image'] },
                                                                    { 'title' => ['Previous Shipwreck File (Again)'], 'creator_family_name' => 'Smith', 'creator_given_name' => nil, 'resource_type' => ['image'] }]
                                             })
    end
  end
end
