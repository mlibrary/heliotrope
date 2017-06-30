# frozen_string_literal: true

require 'rails_helper'
require 'import'

describe Import::Importer do
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:private_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

  let(:root_dir) { File.join(fixture_path, 'csv', 'import_sections') }
  let(:user) { create(:user, email: 'blah@example.com') }
  # let(:user_email) { '' }
  let(:press) { create(:press, subdomain: 'umich') }
  let(:importer) { described_class.new(root_dir: root_dir,
                                       user_email: user.email,
                                       press: press.subdomain,
                                       visibility: public_vis) }
  let(:visibility) { public_vis }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe 'initializer' do
    it 'has a root directory' do
      expect(importer.root_dir).to eq root_dir
    end

    it 'has a user' do
      expect(importer.user_email).to eq user.email
    end

    it 'has a press' do
      expect(importer.press_subdomain).to eq press.subdomain
    end

    it 'has a visibility' do
      expect(importer.visibility).to eq public_vis
    end

    context 'default visibility' do
      let(:importer) { described_class.new(root_dir: root_dir, user_email: user.email, press: press.subdomain) }

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
      # It saves a nice chunk of time (> 10 secs) to test the "reimport" here as well. Ugly though.
      it 'imports the new monograph and files, or "reimports" them to a pre-existing monograph' do
        expect { importer.run }
          .to change { Monograph.count }.by(1)
          .and(change { FileSet.count }.by(9))

        monograph = Monograph.first

        expect(monograph.id.length).to_not eq 36 # GUID
        expect(monograph.id.length).to eq 9 # NOID

        expect(monograph.depositor).to eq user.email

        expect(monograph.visibility).to eq public_vis
        file_sets = monograph.ordered_members.to_a

        expect(file_sets[0].title).to eq ['Monograph Shipwreck']
        expect(file_sets[0].depositor).to eq user.email

        # The monograph cover/representative is the first file_set
        expect(file_sets[0].id).to eq monograph.representative_id

        # Restricted-value fields get lowercased, apart from CC licenses
        expect(file_sets[0].external_resource).to eq 'no'
        expect(file_sets[0].rights_granted_creative_commons).to eq 'Creative Commons Attribution-ShareAlike license, 3.0 Unported'

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

        # ******************************************************
        # *************** Start "reimport" tests ***************
        # ******************************************************

        reimporter = described_class.new(root_dir: root_dir, user_email: user.email, monograph_id: monograph.id)
        expect { reimporter.run }
          .to change { Monograph.count }.by(0)
          .and(change { FileSet.count }.by(9))

        # check it's indeed the same monograph
        expect(Monograph.first.id).to eq monograph.id

        # check counts explicitly
        expect(Monograph.count).to eq(1)
        expect(FileSet.count).to eq(18)

        # grab all FileSets again
        file_sets = Monograph.first.ordered_members.to_a

        # The monograph cover/representative is still the first file_set
        expect(file_sets[0].id).to eq monograph.representative_id

        # check order/existence of new files
        expect(file_sets[9].title).to eq ['Monograph Shipwreck']
        expect(file_sets[10].title).to eq ['Monograph Miranda']
        expect(file_sets[11].title).to eq ['日本語のファイル']
        expect(file_sets[12].title).to eq ['Section 1 Shipwreck']
        expect(file_sets[13].title).to eq ['Section 1 Miranda']
        expect(file_sets[14].title).to eq ['Section 2 Shipwreck']
        expect(file_sets[15].title).to eq ['Section 2 Miranda']
        expect(file_sets[16].title).to eq ['Previous Shipwreck File (Again)']
        expect(file_sets[17].title).to eq ['External Bard Transcript']

        # new filesets should have the same visibility as the parent monograph
        expect(file_sets[10].visibility).to eq monograph.visibility
        expect(file_sets[15].visibility).to eq monograph.visibility
      end
    end

    context 'when the monograph id doesn\'t match a pre-existing monograph' do
      let(:monograph_id) { 'non-existent' }
      let(:reimporter) { described_class.new(root_dir: root_dir, user_email: user.email, monograph_id: monograph_id) }

      it 'raises an exception' do
        expect { reimporter.run }.to raise_error(/No monograph found with id '#{monograph_id}'/)
      end
    end

    context 'when the user_email doesn\'t match a pre-existing user' do
      let(:email_address) { 'non-existent' }
      let(:importer) { described_class.new(root_dir: root_dir, user_email: email_address, press: press.subdomain) }

      it 'raises an exception' do
        expect { importer.run }.to raise_error(/No user found with email '#{email_address}'/)
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
