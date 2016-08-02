require 'rails_helper'
require 'import'

describe Import::MonographBuilder do
  let(:builder) { described_class.new(user, attrs) }
  let(:user) { create(:user) }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:attrs) { { 'title' => ['The Tempest'],
                  'press' => 'umich',
                  'visibility' => public_vis,
                  'publisher' => ['Blah Press'],
                  'subject' => ['Stuff'],
                  'description' => ['The Right Stuff'],
                  'isbn' => ['555-7-5432-1234-9'],
                  'isbn_paper' => ['555-7-5432-1235-0'],
                  'isbn_ebook' => ['555-7-5432-1236-1'],
                  'buy_url' => ['http://example.com'],
                  'files' => [File.new(File.join(Rails.root, 'spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')),
                              File.new(File.join(Rails.root, 'spec', 'fixtures', 'csv', 'import', 'miranda.jpg'))]
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
        expect(monograph.publisher).to eq attrs['publisher']
        expect(monograph.subject).to eq attrs['subject']
        expect(monograph.description).to eq attrs['description']
        expect(monograph.isbn).to eq attrs['isbn']
        expect(monograph.isbn_paper).to eq attrs['isbn_paper']
        expect(monograph.isbn_paper).to eq attrs['isbn_ebook']
        expect(monograph.buy_url).to eq attrs['buy_url']

        expect(monograph.ordered_member_ids.count).to eq 2
        shipwreck, miranda = monograph.ordered_members.to_a

        expect(shipwreck.label).to eq 'shipwreck.jpg'
        expect(miranda.label).to eq 'miranda.jpg'
      end
    end
  end
end
