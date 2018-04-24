# frozen_string_literal: true

module EPub
  class SqlLite
    private_class_method :new
    attr_accessor :epub_publication, :db

    def self.from(epub_publication)
      return null_object unless epub_publication.is_a?(EPub::Publication)

      db = SQLite3::Database.new File.join(EPub.path(epub_publication.id), "#{epub_publication.id}.db")
      new(epub_publication, db)
    rescue StandardError => e
      ::EPub.logger.info("SqlLite.from(#{epub_publication} raised #{e}")
      null_object
    end

    def self.from_directory(root_path)
      return null_object unless File.exist? root_path

      epub_publication = EPub::Publication.from_directory(root_path)
      db = SQLite3::Database.new File.join(root_path, "#{epub_publication.id}.db")
      new(epub_publication, db)
    rescue StandardError => e
      ::EPub.logger.info("SqlLite.from_directory(#{epub_publication} raised #{e} #{e.backtrace}")
      null_object
    end

    def self.null_object
      SqlLiteNullObject.send(:new)
    end

    def create_table
      @db.execute "CREATE VIRTUAL TABLE chapters USING FTS4(chapter_id, chapter_href, title, basecfi, text)"
    rescue SQLite3::Exception => e
      raise "Unable to create VIRTUAL TABLE 'chapters' in #{@db.filename}, #{e}"
    end

    def load_chapters(root_path = nil)
      @epub_publication.chapters(root_path).each do |c|
        text = c.doc.search('//text()').map(&:text).delete_if { |x| x !~ /\w/ }
        @db.execute "INSERT INTO chapters VALUES (?, ?, ?, ?, ?)", c.chapter_id, c.chapter_href, c.title, c.basecfi, text.join(" ")
      end
    rescue SQLite3::Exception => e
      raise "Unable to load chapters to #{@db.filename}, #{e}"
    end

    def search_chapters(query)
      db_results = []
      stm = @db.prepare "SELECT chapter_href, basecfi, title from chapters where chapters MATCH ?"
      # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
      # In FTS4 it's also a token, so we can just remove it without affecting results
      stm.bind_param 1, query.sub("-", " ")
      rs = stm.execute
      rs.each do |row|
        db_results.push(href: row[0], basecfi: row[1], title: row[2])
      end
      db_results
    end

    private

      def initialize(epub_publication, db)
        @epub_publication = epub_publication
        @db = db
      end
  end
end
