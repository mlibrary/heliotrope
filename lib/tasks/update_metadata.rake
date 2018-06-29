# frozen_string_literal: true

desc 'Update metadata fields of Monographs and FileSets'
namespace :heliotrope do
  task update_metadata: :environment do
    puts "Updating metadata ..."
    puts "FileSets"
    FileSet.all.each do |file_set|
      save_flag = false
      save_flag = update_metadata_update_doi(file_set) || save_flag
      save_flag = update_metadata_update_hdl(file_set) || save_flag
      save_flag = update_metadata_update_external_resource_url(file_set) || save_flag
      update_metadata_save_and_reindex(file_set) if save_flag
    end
    puts "Monographs"
    Monograph.all.each do |monograph|
      save_flag = false
      save_flag = update_metadata_update_doi(monograph) || save_flag
      save_flag = update_metadata_update_hdl(monograph) || save_flag
      update_metadata_save_and_reindex(monograph) if save_flag
    end
    puts "done."
  end

  def update_metadata_save_and_reindex(base)
    puts "Saving #{base.id}"
    base.save!
    puts "Perform update index job later #{base.id}"
    CurationConcernUpdateIndexJob.perform_later(base)
  end

  def update_metadata_update_doi(base)
    save_flag = false
    if base.doi.present?
      old_doi = base.doi
      new_doi = base.doi.gsub(/https:\/\/doi\.org\//i, '')
      if old_doi != new_doi
        puts "Updating #{base.id} :doi from #{old_doi} to #{new_doi}"
        base.doi = new_doi
        save_flag = true
      end
    else
      unless base.doi.nil?
        puts "Updating #{base.id} :doi from blank to nil"
        base.doi = nil
        save_flag = true
      end
    end
    save_flag
  end

  def update_metadata_update_hdl(base)
    save_flag = false
    if base.hdl.present?
      puts "Updating #{base.id} :hdl from #{base.hdl} to nil"
      base.hdl = nil
      save_flag = true
    else
      unless base.hdl.nil?
        puts "Updating #{base.id} :hdl from blank to nil"
        base.hdl = nil
        save_flag = true
      end
    end
    save_flag
  end

  def update_metadata_update_external_resource_url(base) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    save_flag = false
    cache_ext_url_doi_or_handle = nil
    cache_external_resource = base.external_resource
    if cache_external_resource.present?
      if /yes|y|true|t/i.match?(cache_external_resource)
        cache_ext_url_doi_or_handle = base.ext_url_doi_or_handle
        if cache_ext_url_doi_or_handle.blank?
          cache_ext_url_doi_or_handle = "http://fulcrum.org/external/resource/url"
        end
      end
      puts "Updating #{base.id} :external_resource from #{cache_external_resource} to nil"
      base.external_resource = nil
      save_flag = true
    else
      unless cache_external_resource.nil?
        puts "Updating #{base.id} :external_resource from blank to nil"
        base.external_resource = nil
        save_flag = true
      end
    end
    if cache_ext_url_doi_or_handle.present?
      puts "Updating #{base.id} :external_resource_url to #{cache_ext_url_doi_or_handle}"
      base.external_resource_url = cache_ext_url_doi_or_handle
      save_flag = true
    end
    unless base.ext_url_doi_or_handle.nil?
      puts "Updating #{base.id} :ext_url_doi_or_handle #{base.ext_url_doi_or_handle} to nil"
      base.ext_url_doi_or_handle = nil
      save_flag = true
    end
    save_flag
  end
end
