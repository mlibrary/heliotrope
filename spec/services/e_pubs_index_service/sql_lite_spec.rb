# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubsIndexService::SqlLite do
  subject { described_class.new(":memory:") }

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
    let(:chapters) { [
      EPubsIndexService::Chapter.new(
        'book title',
        '1',
        '1.xhmtl',
        '/6/2[1.xhtml]!',
        'things about stuff'
      ),
      EPubsIndexService::Chapter.new(
        'book title',
        '2',
        '2.xhtml',
        '/6/4[2.xhtml]!',
        'more things about stuff'
      )
    ] }

    before do
      subject.create_table
      subject.load_chapters(chapters)
    end

    it "loads the chapters" do
      rows = subject.db.execute "select count() from chapters"
      expect(rows[0][0]).to eq 2
    end
  end
end
