# frozen_string_literal: true

require 'sqlite3'

RSpec.describe EPub::SqlLite do
  subject { described_class.from_directory(@root_path) }

  before do
    @noid = '999999991'
    @root_path = UnpackHelper.noid_to_root_path(@noid, 'epub')
    @file = './spec/fixtures/fake_epub01.epub'
    UnpackHelper.unpack_epub(@noid, @root_path, @file)
    allow(EPub.logger).to receive(:info).and_return(nil)
  end

  after do
    FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
  end

  describe "#db_file" do
    it "is a database file" do
      expect(subject.db_file).to eq "./tmp/rspec_derivatives/99/99/99/99/1-epub/999999991.db"
    end
  end

  describe "#create_table" do
    before { subject.create_table }

    it "creates the chapters table" do
      SQLite3::Database.new subject.db_file do |db|
        rows = db.execute "select name from sqlite_master where type='table' and name='chapters'"
        expect(rows[0][0]).to eq 'chapters'
      end
    end
  end

  describe "#load_chapters" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "loads the chapters" do
      SQLite3::Database.new subject.db_file do |db|
        rows = db.execute "select count() from chapters"
        expect(rows[0][0]).to eq 3
      end
    end
  end

  describe "#search_chapters" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "finds the chapters that contain the search query" do
      expect(subject.search_chapters("lieutenant").count).to eq 3
      expect(subject.search_chapters("lieutenant")).to eq [
        {  basecfi: "/6/2[Chapter01]!",  href: "xhtml/Chapter01.xhtml", title: "Damage report!" },
        {  basecfi: "/6/4[Chapter02]!",  href: "xhtml/Chapter02.xhtml", title: "Shields up!" },
        {  basecfi: "/6/6[Chapter03]!",  href: "xhtml/Chapter03.xhtml", title: "Mr. Crusher, ready a collision course with the Borg ship." }
      ]
      expect(subject.search_chapters("szdkfjahykafeh").count).to eq 0
      expect(subject.search_chapters("artifact").count).to eq 1
    end
  end

  describe "with an invalid EPub::Publication object" do
    subject { described_class.from_directory("nothing") }

    it "returns an instance of SqlLiteNullObject" do
      is_expected.to be_an_instance_of(EPub::SqlLiteNullObject)
    end
  end

  describe "#find_by_cfi" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "finds the chapter based on the cfi" do
      expect(subject.find_by_cfi("/6/2[Chapter01]!")[:id]).to eq "Chapter01" # rubocop:disable Rails/DynamicFindBy
      expect(subject.find_by_cfi("/6/2[Chapter01]!")[:title]).to eq "Damage report!" # rubocop:disable Rails/DynamicFindBy
      expect(subject.find_by_cfi("/6/2[Chapter01]!")[:href]).to eq "xhtml/Chapter01.xhtml" # rubocop:disable Rails/DynamicFindBy
    end
  end

  describe "#fetch_chapters" do
    before do
      subject.create_table
      subject.load_chapters
    end

    it "returns the epub chapters" do
      expect(subject.fetch_chapters.count).to eq 3
      expect(subject.fetch_chapters[1][:id]).to eq "Chapter02"
    end
  end
end
