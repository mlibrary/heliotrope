# frozen_string_literal: true

require 'sqlite3'

RSpec.describe EPub::SqlLite do
  subject { described_class.from_directory(root_path) }

  let(:root_path) { double("root_path") }
  let(:epub_publication) { double("publication") }
  let(:chapters) do
    [EPub::Chapter.send(:new,
                        id: '1',
                        href: '1.xhmtl',
                        title: 'Chapter Title 1',
                        basecfi: '/6/2[1.xhtml]!',
                        doc: Nokogiri::XML('<p>things about stuff</p>'),
                        publication: epub_publication),
     EPub::Chapter.send(:new,
                        id: '2',
                        href: '2.xhtml',
                        title: 'Chapter Title 2',
                        basecfi: '/6/4[2.xhtml]!',
                        doc: Nokogiri::XML('<p>more things about stuff</p>'),
                        publication: epub_publication)]
  end

  before do
    allow(EPub::Publication).to receive(:from_directory).with(root_path).and_return(epub_publication)
    allow(epub_publication).to receive(:root_path).and_return(true)
    allow(epub_publication).to receive(:is_a?).and_return(EPub::Publication)
    allow(epub_publication).to receive(:id).and_return('id')
    allow(File).to receive(:join).and_return(":memory:")
    allow(File).to receive(:exist?).with(root_path).and_return(true)
    allow(epub_publication).to receive(:chapters_from_file).and_return(chapters)
  end

  describe "#db" do
    it "is a database" do
      expect(subject.db).to be_instance_of SQLite3::Database
    end
  end

  describe "#create_table" do
    before { subject.create_table }

    it "creates the chapters table" do
      rows = subject.db.execute "select name from sqlite_master where type='table' and name='chapters'"
      expect(rows[0][0]).to eq 'chapters'
    end
  end

  describe "#load_chapters" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "loads the chapters" do
      rows = subject.db.execute "select count() from chapters"
      expect(rows[0][0]).to eq 2
    end
  end

  describe "#search_chapters" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "finds the chapters that contain the search query" do
      expect(subject.search_chapters("stuff").count).to eq 2
      expect(subject.search_chapters("stuff")).to eq [
        { href: "1.xhmtl", basecfi: "/6/2[1.xhtml]!", title: "Chapter Title 1" },
        { href: "2.xhtml", basecfi: "/6/4[2.xhtml]!", title: "Chapter Title 2" }
      ]
      expect(subject.search_chapters("more").count).to eq 1
    end
  end

  describe "with an invalid EPub::Publication object" do
    subject { described_class.from_directory("nothing") }

    it "returns an instance of SqlLiteNullObject" do
      allow(File).to receive(:exist?).with("nothing").and_return(false)
      is_expected.to be_an_instance_of(EPub::SqlLiteNullObject)
    end
  end
end
