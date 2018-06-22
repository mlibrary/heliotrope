# frozen_string_literal: true

desc 'Update :doi and :hdl metadata fields of Monographs and FileSets'
namespace :heliotrope do
  task update_doi_hdl: :environment do
    puts "Updating doi and hdl ..."
    Monograph.all.each do |monograph|
      save_flag = false
      if monograph.hdl.present?
        puts "Updating Monograph #{monograph.id} :hdl from #{monograph.hdl} to nil"
        monograph.hdl = nil
        save_flag = true
      end
      if monograph.doi.present?
        old_doi = monograph.doi
        new_doi = monograph.doi.gsub(/https:\/\/doi\.org\//i, '')
        if old_doi != new_doi
          puts "Updating Mongraph #{monograph.id} :doi from #{old_doi} to #{new_doi}"
          monograph.doi = new_doi
          save_flag = true
        end
      end
      puts "Uncomment next line to save Monograph #{monograph.id}" if save_flag
      # monograph.save! if save_flag
    end
    FileSet.all.each do |fileset|
      save_flag = false
      if fileset.hdl.present?
        puts "Updating FileSet #{fileset.id} :hdl from #{fileset.hdl} to nil"
        fileset.hdl = nil
        save_flag = true
      end
      if fileset.doi.present?
        old_doi = fileset.doi
        new_doi = fileset.doi.gsub(/https:\/\/doi\.org\//i, '')
        if old_doi != new_doi
          puts "Updating FileSet #{fileset.id} :doi from #{old_doi} to #{new_doi}"
          fileset.doi = new_doi
          save_flag = true
        end
      end
      puts "Uncomment next line to save FileSet #{fileset.id}" if save_flag
      # fileset.save! if save_flag
    end
    puts "... updated."
  end
end
