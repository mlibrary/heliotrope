require 'rails_helper'
require 'import'

describe Import::MonographBuilder do
  let(:builder) { described_class.new(user, attrs) }
  let(:user) { create(:user) }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:attrs) { { 'title' => ['The Tempest'],
                  'press' => 'umich',
                  'visibility' => public_vis,
                  'files' => [File.new(File.join(Rails.root, 'spec', 'fixtures', 'csv', 'tempest', 'act1', 'shipwreck.jpg')),
                              File.new(File.join(Rails.root, 'spec', 'fixtures', 'csv', 'tempest', 'miranda.jpg'))]
  } }

  describe 'initialize' do
    it 'has a user' do
      expect(builder.user).to eq user
    end

    it 'has attributes' do
      expect(builder.attributes).to eq attrs
    end
  end

  describe '#run' do
    before do
      Monograph.destroy_all
      stub_out_redis
    end

    context 'when the builder runs successfully' do
      it 'creates a monograph record in fedora' do
        expect { builder.run }
          .to change { Monograph.count }.by(1)

        expect(Monograph.count).to eq 1
        monograph = Monograph.first

        expect(monograph.title).to eq attrs['title']
        expect(monograph.press).to eq attrs['press']
        expect(monograph.visibility).to eq attrs['visibility']

        expect(monograph.ordered_member_ids.count).to eq 2
        shipwreck, miranda = monograph.ordered_members.to_a

        expect(shipwreck.label).to eq 'shipwreck.jpg'
        expect(miranda.label).to eq 'miranda.jpg'
      end
    end
  end
end
