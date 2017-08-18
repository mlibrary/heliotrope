# frozen_string_literal: true

require 'sqlite3'
require 'fileutils'

module EPubsIndexService
  class SqlLite
    attr_accessor :db, :db_file
    def initialize(db_file)
      @db_file = db_file
      FileUtils.rm @db_file if File.exist? @db_file

      @db = SQLite3::Database.new @db_file
    rescue SQLite3::Exception => e
      raise "Unable to create #{@db_file}, #{e}"
    end

    def create_table
      @db.execute "CREATE VIRTUAL TABLE chapters USING FTS4(book_title, chapter_id, href, basecfi, body)"
    rescue SQLite3::Exception => e
      raise "Unable to create VIRTUAL TABLE 'chapters' in #{@db_file}, #{e}"
    end

    def load_chapters(chapters)
      chapters.each do |c|
        @db.execute "INSERT INTO chapters VALUES (?, ?, ?, ?, ?)", c.book_title, c.chapter_id, c.href, c.basecfi, c.body
      end
    rescue SQLite3::Exception => e
      raise "Unable to load chapters to #{@db_file}, #{e}"
    end
  end
end
