# frozen_string_literal: true

class UpdatePressMetadataJob < ApplicationJob
  queue_as :default

  def perform(subdomain:, old_subdomain: nil, subdomain_changed: false, name_changed: false)
    current_press = Press.includes(:parent).find_by(subdomain: subdomain)
    return if current_press.blank?

    if subdomain_changed
      # SCENARIO A: Subdomain changed (or BOTH changed)
      Monograph.where(press_sim: old_subdomain).find_each(batch_size: 100) do |monograph|
        # 1. Update the ActiveFedora structural property string
        monograph.press = subdomain

        # 2. Inject the preloaded press object to keep MonographIndexer database-free
        monograph.instance_variable_set(:@preloaded_press_object, current_press)

        # 3. Save to Fedora & reindex the Monograph
        monograph.save

        # 4. CRITICAL: Reindex child FileSets so the admin facet stays accurate
        monograph.file_sets.each do |file_set|
          # Passing the updated monograph ensures FileSetIndexer maps the new string seamlessly
          file_set.instance_variable_set(:@monograph, monograph)
          ActiveFedora::SolrService.add(file_set.to_solr)
        end
      end
      ActiveFedora::SolrService.commit

    elsif name_changed
      # SCENARIO B: Only the Name changed
      solr_docs = []

      Monograph.where(press_sim: subdomain).find_each(batch_size: 100) do |monograph|
        monograph.instance_variable_set(:@preloaded_press_object, current_press)
        solr_docs << monograph.to_solr

        if solr_docs.size >= 100
          ActiveFedora::SolrService.add(solr_docs)
          solr_docs.clear
        end
      end

      ActiveFedora::SolrService.add(solr_docs) if solr_docs.any?
      ActiveFedora::SolrService.commit
    end
  end
end
