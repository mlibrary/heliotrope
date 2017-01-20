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

    # order of asset metadata here is as in lib/import.rb
    it 'collects attributes from the CSV file' do
      expect(subject['monograph']['title']).to eq ['The Tempest', 'A Subtitle']
      expect(subject['monograph']['creator_family_name']).to eq 'Shakespeare'
      expect(subject['monograph']['creator_given_name']).to eq 'William'
      expect(subject['monograph']['contributor']).to eq ['Christopher Marlowe', 'Sir Francis Bacon']
      expect(subject['monograph']['subject']).to eq ['Dog', 'Cat', 'Mouse']
      expect(subject['monograph']['files']).to eq ['shipwreck.jpg', 'miranda.jpg', 'ファイル.txt']
      expect(subject['monograph']['files_metadata']).to eq [
        { 'title' => ['Monograph Shipwreck'],
          'creator_family_name' => 'Smith',
          'creator_given_name' => 'Benjamin',
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'exclusive_to_platform' => 'no',
          'rights_granted_creative_commons' => 'Creative Commons Attribution-ShareAlike license, 3.0 Unported',
          'content_type' => ['portrait'],
          'language' => ['English'] },
        { 'title' => ['Monograph Miranda'],
          'creator_family_name' => 'Waterhouse',
          'creator_given_name' => 'John William',
          'resource_type' => ['image'],
          'external_resource' => 'no',
          'exclusive_to_platform' => 'yes',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'content_type' => ['audience materials'],
          'language' => ['English', 'German'] },
        { 'title' => ['日本語のファイル'],
          'resource_type' => ['text'],
          'external_resource' => 'no',
          'exclusive_to_platform' => 'yes',
          'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
          'content_type' => ['portrait', 'illustration'],
          'language' => ['Japanese'] }
      ]

      # order of asset metadata here is as in lib/import.rb
      expect(subject['sections'])
        .to include('Act 1: Calm Waters' => { 'title' => ['Act 1: Calm Waters'],
                                              'files' => ['shipwreck1.jpg', 'miranda1.jpg'],
                                              'files_metadata' => [{ 'title' => ['Section 1 Shipwreck'],
                                                                     'creator_family_name' => 'Smith',
                                                                     'resource_type' => ['image'],
                                                                     'external_resource' => 'no',
                                                                     'exclusive_to_platform' => 'yes',
                                                                     'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
                                                                     'content_type' => ['audience materials'],
                                                                     'keywords' => ['keyword1', 'keyword2'],
                                                                     'language' => ['Russian'] },
                                                                   { 'title' => ['Section 1 Miranda'],
                                                                     'creator_family_name' => 'Waterhouse',
                                                                     'creator_given_name' => 'John William',
                                                                     'resource_type' => ['image'],
                                                                     'external_resource' => 'no',
                                                                     'exclusive_to_platform' => 'yes',
                                                                     'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
                                                                     'content_type' => ['portrait'],
                                                                     'keywords' => ['regular', 'italicized'],
                                                                     'language' => ['Russian', 'German', 'French'] }
                                                                   ]
                                            })

      expect(subject['sections'])
        .to include('Act 2: Stirrin\' Up' => { 'title' => ['Act 2: Stirrin\' Up'],
                                               'files' => ['shipwreck2.jpg', 'miranda2.jpg', 'shipwreck1.jpg'],
                                               'files_metadata' => [{ 'title' => ['Section 2 Shipwreck'],
                                                                      'creator_family_name' => 'Smith',
                                                                      'resource_type' => ['image'],
                                                                      'external_resource' => 'no',
                                                                      'exclusive_to_platform' => 'yes',
                                                                      'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
                                                                      'content_type' => ['audience materials'],
                                                                      'language' => ['French'] },
                                                                    { 'title' => ['Section 2 Miranda'],
                                                                      'creator_family_name' => 'Waterhouse',
                                                                      'creator_given_name' => 'John William',
                                                                      'resource_type' => ['image'],
                                                                      'external_resource' => 'no',
                                                                      'exclusive_to_platform' => 'yes',
                                                                      'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
                                                                      'content_type' => ['illustration'],
                                                                      'language' => ['English'] },
                                                                    { 'title' => ['Previous Shipwreck File (Again)'],
                                                                      'creator_family_name' => 'Smith',
                                                                      'resource_type' => ['image'],
                                                                      'external_resource' => 'no',
                                                                      'exclusive_to_platform' => 'yes',
                                                                      'rights_granted_creative_commons' => 'Creative Commons Zero license (implies pd)',
                                                                      'content_type' => ['portrait', 'photograph'],
                                                                      'language' => ['Latin'] }
                                                                    ]
                                             })
    end
  end
end
