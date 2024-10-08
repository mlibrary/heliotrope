# frozen_string_literal: true

module EmbedCodeService
  extend ActiveSupport::Concern

  def insert_embed_codes(parent_id, epub_dir)
    monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [parent_id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
    return unless monograph_presenter.non_representative_file_sets?

    # first get all the Monograph's FileSets' Solr docs, then whittle out the "representative" ones
    embeddable_file_set_docs = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND monograph_id_ssim:#{parent_id} AND +label_ssi:['' TO *]", rows: 100_000)
    embeddable_file_set_docs = embeddable_file_set_docs.select { |doc| monograph_presenter.non_representative_file_set_ids.include?(doc.id) }

    # Find all XHTML files in this directory and its subdirectories
    Dir.glob("#{epub_dir}/**/*.xhtml").each do |file|
      doc = File.open(file) { |f| Nokogiri::XML(f) }

      # NB: we need to figure out what (screen-reader only) heading level _might_ be appropriate to automatically add...
      # at any given "embed-altered" node. It only really makes sense to do this before the document has been altered...
      # in any way, seeing as any added headings will alter this calculation. Hence nodes which embeds will target...
      # need to be gathered and stored while that analysis is done.

      # "data attribute embed" nodes should look something like this:
      # <figure data-fulcrum-embed-filename="audio_file_name.mp3">
      data_attribute_embed_nodes = doc.search 'figure[data-fulcrum-embed-filename]'
      heading_tags_for_data_attribute_embed_nodes = heading_tags_for_nodes(doc, data_attribute_embed_nodes)

      # "img src basename embed" nodes should look like regular img tags:
      # <img src="images/video_file_basename.jpg" alt="local image representing a video embed"/>
      # note: `data-fulcrum-embed="false"` allows img tags with matching Monograph resource FileSet basenames to *not* cause an embed
      img_src_basename_embed_nodes = doc.search 'img:not([data-fulcrum-embed="false"])'
      heading_tags_for_img_src_basename_embed_nodes = heading_tags_for_nodes(doc, img_src_basename_embed_nodes)

      # now, we can actually make the changes to the document, adding headings (where appropriate) and embed codes
      data_attribute_embeds(data_attribute_embed_nodes, heading_tags_for_data_attribute_embed_nodes, embeddable_file_set_docs) if data_attribute_embed_nodes.present?
      img_src_basename_embeds(img_src_basename_embed_nodes, heading_tags_for_img_src_basename_embed_nodes, embeddable_file_set_docs) if img_src_basename_embed_nodes.present?

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
    elsif file_set_presenter.interactive_application?
      'interactive-application'
    elsif file_set_presenter.interactive_map?
      'interactive-map'
    else
      'resource' # probably should never happen
    end
  end

  def data_attribute_embeds(nodes, heading_tags_for_nodes, embeddable_file_set_docs) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/BlockLength
    nodes.each_with_index do |node, index| # rubocop:disable Metrics/BlockLength
      next if node['data-fulcrum-embed-filename']&.gsub(/\s+/, "").blank?

      matching_files = match_files(embeddable_file_set_docs, node['data-fulcrum-embed-filename'])
      next unless matching_files.count == 1 # there must only be one file found to add the embed code
      id = matching_files&.first&.id

      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      next unless file_set_presenter.embeddable_type?

      # additional resources are expected to have a `style="display:none"` attribute present, to keep them hidden in...
      # the EPUB off-Fulcrum. There is no other reason they would have a style attribute, so delete it completely.
      node.remove_attribute('style')

      figcaption = node.at('figcaption')

      if file_set_presenter.interactive_application? || file_set_presenter.interactive_map?
        # these data attributes prompt CSB to add a button that opens the embedded FileSet in a modal
        # see https://github.com/mlibrary/cozy-sun-bear/blob/51b7e4e62be0e4b0afb6c43b08fbbc46de312204/src/utils/manglers.js#L189
        node['data-href'] = file_set_presenter.embed_link
        node['data-title'] = file_set_presenter.embed_code_title
        node['data-resource-type'] = resource_type(file_set_presenter)

        # the `data-resource-trigger` element allows us to decide where the modal-opening button will go, so we'll...
        # add it above the <figcaption>, if the interactive application/map already has one in the EPUB. Otherwise...
        # put it as the last element in the <figure> for now, given that an automatic <figcaption> will come next.
        # see https://github.com/mlibrary/cozy-sun-bear/blob/8fb409d269b2e7cbdaf7bd3ac46055f357dc67ee/src/utils/manglers.js#L199-L202
        if figcaption.present?
          figcaption.add_previous_sibling("<div data-resource-trigger></div>")
        else
          node.add_child("<div data-resource-trigger></div>")
        end

      else
        heading = heading_node(heading_tags_for_nodes[index], file_set_presenter)

        # for these full embed markup is added inside the <figure> element in the derivative-folder XHTML file
        # we must ensure this node is inserted above any existing <figcaption>
        if figcaption.present?
          figcaption.add_previous_sibling(heading) if heading.present?
          figcaption.add_previous_sibling(file_set_presenter.embed_code)
        else
          node.add_child(heading) if heading.present?
          node.add_child(file_set_presenter.embed_code)
        end
      end

      maybe_add_figcaption(node, file_set_presenter) if figcaption.blank?
    end
  end

  def img_src_basename_embeds(nodes, heading_tags_for_nodes, embeddable_file_set_docs) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    nodes.each_with_index do |node, index|
      next if node['src']&.gsub(/\s+/, "").blank?

      matching_files = match_files_by_basename(embeddable_file_set_docs, node['src'])
      next unless matching_files.count == 1 # there must only be one file found to add the embed code
      id = matching_files&.first&.id

      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      next unless file_set_presenter.embeddable_type?

      # both embed code methods require node's parents to hold new div elements, so the parent cannot be a p
      node.parent.name = 'div' if node.parent.name == 'p'

      if file_set_presenter.interactive_application? || file_set_presenter.interactive_map?
        # these data attributes prompt CSB to add embed modal and button
        # see https://github.com/mlibrary/cozy-sun-bear/blob/51b7e4e62be0e4b0afb6c43b08fbbc46de312204/src/utils/manglers.js#L189
        node.add_next_sibling("<div data-href=\"#{file_set_presenter.embed_link}\" " \
                              "data-title=\"#{file_set_presenter.embed_code_title}\" " \
                              "data-resource-type=\"#{resource_type(file_set_presenter)}\" />")
      else
        heading = heading_node(heading_tags_for_nodes[index], file_set_presenter)

        # full embed markup added to XHTML file for these
        # the local image is no longer needed, just replace it with the embed code
        if heading.present?
          node.replace("#{heading}#{file_set_presenter.embed_code}")
        else
          node.replace(file_set_presenter.embed_code)
        end
      end
    end
  end

  def maybe_add_figcaption(node, file_set_presenter)
    # skip if there is a figcaption anywhere under this node
    return if node.at('figcaption').present?
    caption = file_set_presenter.caption.present? ? file_set_presenter.caption.first : "Additional #{resource_type(file_set_presenter).titlecase} Resource"
    node.add_child("<figcaption>#{caption}</figcaption>")
  end

  def heading_node(heading_tag_for_node, file_set_presenter)
    # this whole "auto-heading" deal only applies to Able Player embeds (so, audio or video)
    return nil unless file_set_presenter.audio? || file_set_presenter.video?
    # https://uit.stanford.edu/accessibility/concepts/screen-reader-only-content
    "<#{heading_tag_for_node} style=\"clip: rect(1px, 1px, 1px, 1px); clip-path: inset(50%); height: 1px; width: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute;\">Media player: #{file_set_presenter.embed_code_title}</#{heading_tag_for_node}>"
  end

  def heading_tags_for_nodes(doc, nodes)
    headings_for_nodes = []

    nodes.each do |node|
      best_heading = nil
      doc.traverse do |recursive_child_node|
        break if recursive_child_node == node
        if ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].include? recursive_child_node.name
          best_heading = recursive_child_node.name
        end
      end

      nearest_heading_up_level = best_heading.nil? ? 0 : best_heading.delete('h').to_i
      # the embed being nested under a 6 seems unlikely enough that I'm not going to fret over it, we'll add another 6!
      nearest_heading_up_level += 1 if nearest_heading_up_level < 6

      headings_for_nodes << "h#{nearest_heading_up_level}"
    end
    headings_for_nodes
  end
end
