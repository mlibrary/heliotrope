require 'rails_helper'
require 'import/csv_parser'

describe Import::CSVParser do
  let(:input_file) { File.join(fixture_path, 'csv', 'import_blanks', 'tempest_blanks.csv') }
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
    subject { parser.attributes['monograph'] }

    it 'collects attributes from the CSV file' do
      expect(subject['title']).to eq ['The Tempest', 'A Subtitle']
      expect(subject['creator_family_name']).to eq 'Shakespeare'
      expect(subject['creator_given_name']).to eq 'William'
      expect(subject['files']).to eq ['shipwreck.jpg', 'miranda.jpg']
      expect(subject['files_metadata']).to eq [
        { 'title' => ['The shipwreck scene in Act I, Scene 1'],
          'creator_family_name' => 'Smith' },
        { 'title' => ['Miranda'],
          'creator_family_name' => 'Waterhouse',
          'creator_given_name' => 'John William' }
      ]
    end
  end
end
