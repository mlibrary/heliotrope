# frozen_string_literal: true

require 'rails_helper'
require 'import'

describe Import::Importer do
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:root_dir) { File.join(fixture_path, 'csv', 'import_representatives') }
  let(:user) { create(:user, email: 'blah@example.com') }
  let(:press) { create(:press, subdomain: 'umich') }
  let(:importer) {
    described_class.new(root_dir: root_dir,
                        user_email: user.email,
                        press: press.subdomain,
                        visibility: public_vis,
                        quiet: true)
  }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    before do
      stub_out_redis
    end

    context 'when the importer runs successfully and has a column for representative_kind' do
      it 'imports the new monograph and files, and sets the representatives' do
        expect { importer.run }
          .to change(Monograph, :count)
          .by(1)
          .and(change(FileSet, :count)
          .by(3))
          .and(change(FeaturedRepresentative, :count)
          .by(1))

        monograph = Monograph.first
        file_sets = monograph.ordered_members.to_a

        # epub representative is correct
        expect(file_sets[0].id).to eq FeaturedRepresentative.where(monograph_id: monograph.id, kind: 'epub').first.file_set_id
        # The monograph cover/representative is explicitly set in the CSV (not the first file_set)
        expect(file_sets[1].id).to eq monograph.representative_id
        expect(file_sets[1].id).to eq monograph.thumbnail_id
      end
    end
  end
end
