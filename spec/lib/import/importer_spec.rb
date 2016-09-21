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
      Monograph.destroy_all
      Section.destroy_all
      FileSet.destroy_all
    end

    context 'when the importer runs successfully' do
      it 'imports the monograph, sections and files' do
        expect { importer.run }
          .to change { Monograph.count }.by(1)
          .and(change { Section.count }.by(2))
          .and(change { FileSet.count }.by(8))

        monograph = Monograph.first
        expect(monograph.visibility).to eq public_vis

        sections = Monograph.first.ordered_members.to_a.select { |m| m.class.name == 'Section' }
        section = sections.first
        expect(section.visibility).to eq public_vis
        expect(section.title).to eq ['Act 1: Calm Waters']
        # Test that the FileSetBuilder got called to add the
        # metadata to the FileSets.
        shipwreck = monograph.ordered_members.to_a.first
        expect(shipwreck.title).to eq ['Monograph Shipwreck']
        miranda = monograph.ordered_members.to_a.second
        expect(miranda.title).to eq ['Monograph Miranda']
        japanese = monograph.ordered_members.to_a.third
        expect(japanese.title).to eq ['日本語のファイル']

        shipwreck = section.ordered_members.to_a.first
        expect(shipwreck.title).to eq ['Section 1 Shipwreck']
        miranda = section.ordered_members.to_a.second
        expect(miranda.title).to eq ['Section 1 Miranda']

        # restricted-value fields get lowercased, apart from CC licenses
        shipwreck = monograph.ordered_members.to_a.first
        expect(shipwreck.external_resource).to eq 'no'
        expect(shipwreck.rights_granted_creative_commons).to eq 'Creative Commons Attribution-ShareAlike license, 3.0 Unported'
        miranda = monograph.ordered_members.to_a.second
        expect(miranda.external_resource).to eq 'no'
        expect(miranda.rights_granted_creative_commons).to eq 'Creative Commons Zero license (implies pd)'

        # exclusivity should be transformed from P/BP to yes/no
        expect(shipwreck.exclusive_to_platform).to eq 'no'
        expect(miranda.exclusive_to_platform).to eq 'yes'
      end
    end

    context 'when the importer runs (reversing the rows) successfully' do
      it 'imports the sections (unreversed) and files (reversed)' do
        expect { importer.run(true, nil, nil) }
          .to change { Monograph.count }.by(1)
          .and(change { Section.count }.by(2))
          .and(change { FileSet.count }.by(8))

        monograph = Monograph.first
        expect(monograph.visibility).to eq public_vis

        # sections not reversed
        sections = Monograph.first.ordered_members.to_a.select { |m| m.class.name == 'Section' }
        section = sections.first
        expect(section.visibility).to eq public_vis
        expect(section.title).to eq ['Act 1: Calm Waters']

        # files reversed within monographs and sections
        japanese = monograph.ordered_members.to_a.first
        expect(japanese.title).to eq ['日本語のファイル']
        miranda = monograph.ordered_members.to_a.second
        expect(miranda.title).to eq ['Monograph Miranda']
        miranda = monograph.ordered_members.to_a.third
        expect(miranda.title).to eq ['Monograph Shipwreck']

        shipwreck = section.ordered_members.to_a.first
        expect(shipwreck.title).to eq ['Section 1 Miranda']
        miranda = section.ordered_members.to_a.second
        expect(miranda.title).to eq ['Section 1 Shipwreck']
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
