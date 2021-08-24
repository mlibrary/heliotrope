# frozen_string_literal: true

module EmbedCodeService
  extend ActiveSupport::Concern

  def insert_embed_codes(parent_id, epub_dir)
    monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [parent_id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
    return unless monograph_presenter.non_representative_file_sets? && Socket.gethostname != 'bulleit-1.umdl.umich.edu'

    # first get all the Monograph's FileSets' Solr docs, then whittle out the "representative" ones
    embeddable_file_set_docs = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND monograph_id_ssim:#{parent_id} AND +label_ssi:['' TO *]", rows: 100_000)
    embeddable_file_set_docs = embeddable_file_set_docs.select { |doc| monograph_presenter.non_representative_file_set_ids.include?(doc.id) }

    # Find all XHTML files in this directory and its subdirectories
    Dir.glob("#{epub_dir}/**/*.xhtml").each do |file|
      doc = File.open(file) { |f| Nokogiri::XML(f) }

      # these should look something like this
      # <div data-embed-filename="audio_file_name.mp3">
      nodes = doc.search '[data-fulcrum-embed-filename]'
      data_attribute_embeds(nodes, embeddable_file_set_docs) if nodes.present?

      # these should look like regular img tags
      # <img src="images/video_file_basename.jpg" alt="local image representing a video embed"/>
      # `data-fulcrum-embed="false"` allows img tags with matching Monograph resource FileSet basenames to *not* cause an embed
      nodes = doc.search 'img:not([data-fulcrum-embed="false"])'
      img_src_basename_embeds(nodes, embeddable_file_set_docs) if nodes.present?

      File.write(file, doc)
    end
  end

  def match_files(file_docs, filename)
    file_docs.select { |file_doc| file_doc['label_ssi'].to_s.downcase == filename.to_s.strip.downcase }
  end

  def match_files_by_basename(file_docs, filename)
    file_docs.select { |file_doc| File.basename(file_doc['label_ssi'].to_s, ".*").downcase == File.basename(filename.to_s.strip, ".*").downcase }
  end

  def resource_type(file_set_presenter)
    if file_set_presenter.image?
      'image'
    elsif file_set_presenter.video?
      'video'
    elsif file_set_presenter.audio?
      'audio'
    elsif file_set_presenter.interactive_map?
      'interactive-map'
    else
      'resource' # probably should never happen
    end
  end

  def data_attribute_embeds(nodes, embeddable_file_set_docs)
    nodes.each do |node|
      next if node['data-fulcrum-embed-filename']&.gsub(/\s+/, "").blank?

      matching_files = match_files(embeddable_file_set_docs, node['data-fulcrum-embed-filename'])
      next unless matching_files.count == 1 # there must only be one file found to add the embed code
      id = matching_files&.first&.id

      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      next unless file_set_presenter.embeddable_type?

      node['data-href'] = file_set_presenter.embed_link
      node['data-title'] = file_set_presenter.embed_code_title
      node['data-resource-type'] = resource_type(file_set_presenter)
    end
  end

  def img_src_basename_embeds(nodes, embeddable_file_set_docs)
    nodes.each do |node|
      next if node['src']&.gsub(/\s+/, "").blank?

      matching_files = match_files_by_basename(embeddable_file_set_docs, node['src'])
      next unless matching_files.count == 1 # there must only be one file found to add the embed code
      id = matching_files&.first&.id

      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      next unless file_set_presenter.embeddable_type?

      # The modal-triggering button will be added in a dynamically-added div within the sibling div we're adding...
      # below, so the parent of the img cannot be a paragraph, which it often is. Swap it to a div.
      # This is the added div: https://github.com/mlibrary/cozy-sun-bear/blob/51b7e4e62be0e4b0afb6c43b08fbbc46de312204/src/utils/manglers.js#L189
      node.parent.name = 'div' if node.parent.name == 'p'
      node.add_next_sibling("<div data-href=\"#{file_set_presenter.embed_link}\" " \
                            "data-title=\"#{file_set_presenter.embed_code_title}\" " \
                            "data-resource-type=\"#{resource_type(file_set_presenter)}\" />")
    end
  end
end
