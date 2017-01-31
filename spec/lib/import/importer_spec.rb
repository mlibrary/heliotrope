require 'rails_helper'
require 'import'

describe Import::Importer do
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:private_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

  let(:root_dir) { File.join(fixture_path, 'csv', 'import_sections') }
  let(:press) { Press.find_or_create_by(subdomain: 'umich') }
  let(:importer) { described_class.new(root_dir, press.subdomain, visibility) }
  let(:visibility) { public_vis }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe 'initializer' do
    it 'has a root directory' do
      expect(importer.root_dir).to eq root_dir
    end

    it 'has a press' do
      expect(importer.press_subdomain).to eq press.subdomain
    end

    it 'has a visibility' do
      expect(importer.visibility).to eq public_vis
    end

    context 'default visibility' do
      let(:importer) { described_class.new(root_dir, press.subdomain) }

      it 'is private' do
        expect(importer.visibility).to eq private_vis
      end
    end
  end

  describe '#run' do
    before do
      stub_out_redis
    end

    context 'when the importer runs successfully' do
      it 'imports the monograph, sections and files' do
        expect { importer.run }
          .to change { Monograph.count }.by(1)
          .and(change { FileSet.count }.by(8))

        monograph = Monograph.first
        expect(monograph.visibility).to eq public_vis

        file_sets = monograph.ordered_members.to_a

        expect(file_sets[0].title).to eq ['Monograph Shipwreck']

        # The monograph cover/representative is the first file_set
        expect(file_sets[0].id).to eq monograph.representative_id

        # Restricted-value fields get lowercased, apart from CC licenses
        expect(file_sets[0].external_resource).to eq 'no'
        expect(file_sets[0].rights_granted_creative_commons).to eq 'Creative Commons Attribution-ShareAlike license, 3.0 Unported'

        # Exclusivity should be transformed from P/BP to yes/no
        expect(file_sets[0].exclusive_to_platform).to eq 'no'

        expect(file_sets[1].title).to eq ['Monograph Miranda']
        expect(file_sets[1].external_resource).to eq 'no'
        expect(file_sets[1].rights_granted_creative_commons).to eq 'Creative Commons Zero license (implies pd)'
        expect(file_sets[1].exclusive_to_platform).to eq 'yes'

        expect(file_sets[2].title).to eq ['日本語のファイル']

        # FileSets w/ sections
        expect(file_sets[3].title).to eq ['Section 1 Shipwreck']
        expect(file_sets[3].section_title).to eq ['Act 1: Calm Waters']

        expect(file_sets[4].title).to eq ['Section 1 Miranda']
        expect(file_sets[4].section_title).to eq ['Act 1: Calm Waters']

        expect(file_sets[5].title).to eq ['Section 2 Shipwreck']
        expect(file_sets[5].section_title).to eq ['Act 2: Stirrin\' Up']
      end
    end

    context 'when the root directory doesnt exist' do
      let(:root_dir) { File.join(fixture_path, 'bad_directory') }
      it 'raises an exception' do
        expect { importer.run }.to raise_error(/Directory not found/)
      end
    end

    context 'when the press is invalid' do
      let(:press) { Press.new(subdomain: 'incorrect press') }

      it 'raises an exception' do
        expect { importer.run }.to raise_error(/No press found with subdomain: 'incorrect press'/)
      end
    end
  end
end
