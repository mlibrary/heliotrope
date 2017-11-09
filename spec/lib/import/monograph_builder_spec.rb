# frozen_string_literal: true

require 'rails_helper'
require 'import'

describe Import::MonographBuilder do
  let(:builder) { described_class.new(user, attrs) }
  let(:user) { create(:user) }
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:file1) { File.new(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')) }
  let(:file2) { File.new(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'miranda.jpg')) }
  let(:uploaded_file1) { Hyrax::UploadedFile.create(user: user, file: file1) }
  let(:uploaded_file2) { Hyrax::UploadedFile.create(user: user, file: file2) }
  let(:attrs) { { 'title' => ['The Tempest'],
                  'press' => 'umich',
                  'visibility' => public_vis,
                  'publisher' => ['Blah Press'],
                  'subject' => ['Stuff', 'Things'],
                  'description' => ['The Right Stuff'],
                  'isbn' => ['555-7-5432-1234-9'],
                  'isbn_paper' => ['555-7-5432-1235-0'],
                  'isbn_ebook' => ['555-7-5432-1236-1'],
                  'buy_url' => ['http://example.com'],
                  'uploaded_files' => [uploaded_file1.id, uploaded_file2.id] } }

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
      stub_out_redis
    end

    context 'when the builder runs successfully' do
      it 'creates a monograph record in fedora' do
        expect { builder.run }
          .to change { Monograph.count }.by(1)

        expect(Monograph.count).to eq 1
        monograph = Monograph.first

        expect(monograph.id.length).to_not eq 36 # GUID
        expect(monograph.id.length).to eq 9 # NOID

        expect(monograph.title).to eq attrs['title']
        expect(monograph.press).to eq attrs['press']
        expect(monograph.visibility).to eq attrs['visibility']
        expect(monograph.publisher).to eq attrs['publisher']
        expect(monograph.subject).to eq attrs['subject']
        expect(monograph.description).to eq attrs['description']
        expect(monograph.isbn).to eq attrs['isbn']
        expect(monograph.isbn_paper).to eq attrs['isbn_paper']
        expect(monograph.isbn_ebook).to eq attrs['isbn_ebook']
        expect(monograph.buy_url).to eq attrs['buy_url']
        expect(monograph.subject.count).to eq 2

        expect(monograph.ordered_member_ids.count).to eq 2
        shipwreck, miranda = monograph.ordered_members.to_a

        expect(shipwreck.label).to eq 'shipwreck.jpg'
        expect(miranda.label).to eq 'miranda.jpg'
      end
    end
  end
end
