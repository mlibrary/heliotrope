# frozen_string_literal: true

desc 'Purge metadata fields from Monographs and FileSets'
namespace :heliotrope do
  task purge_metadata: :environment do
    puts "Purging metadata from FileSets..."
    FileSet.all.each do |file_set|
      save_flag = false
      save_flag = purge_metadata_book_needs_handles(file_set) || save_flag
      save_flag = purge_metadata_use_crossref_xml(file_set) || save_flag
      purge_metadata_save(file_set) if save_flag
    end
    puts "done."
  end

  def purge_metadata_save(base)
    puts "Saving #{base.id}"
    base.save!
  end

  def purge_metadata_book_needs_handles(base)
    save_flag = false
    unless base.book_needs_handles.nil?
      puts "Purging :book_needs_handles from #{base.id}"
      base.book_needs_handles = nil
      save_flag = true
    end
    save_flag
  end

  def purge_metadata_use_crossref_xml(base)
    save_flag = false
    unless base.use_crossref_xml.nil?
      puts "Purging :use_crossref_xml from #{base.id}"
      base.use_crossref_xml = nil
      save_flag = true
    end
    save_flag
  end
end
