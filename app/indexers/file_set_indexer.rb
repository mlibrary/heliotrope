# frozen_string_literal: true

class FileSetIndexer < Hyrax::FileSetIndexer
  attr_reader :monograph

  def generate_solr_document # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    super.tap do |solr_doc| # rubocop:disable Metrics/BlockLength
      # Removing punctuation so that a title starting with quotes doesn't always come first
      solr_doc['title_si'] = object&.title&.first&.downcase&.gsub(/[^\w\s\d-]/, '')
      solr_doc['resource_type_si'] = object&.resource_type&.first

      roleless_creators = multiline_names_minus_role('creator')
      solr_doc['creator_tesim'] = roleless_creators
      solr_doc['creator_sim'] = roleless_creators
      solr_doc['creator_full_name_tesim'] = roleless_creators&.first
      primary_creator_role = first_creator_roles
      solr_doc['primary_creator_role_tesim'] = primary_creator_role
      solr_doc['primary_creator_role_sim'] = primary_creator_role
      solr_doc['contributor_tesim'] = multiline_contributors # include roles
      # index authorship fields as they are stored in importable backup files, for fast access use, e.g. ScholarlyiQ rake tasks
      solr_doc['creator_ss'] = importable_backup_authorship_value('creator')
      solr_doc['contributor_ss'] = importable_backup_authorship_value('contributor')

      # Extra technical metadata we need to index
      # These are apparently not necessarily integers all the time, so index them as symbols
      index_technical_metadata(solr_doc, object.original_file) if !object.original_file.nil?

      # Neither we nor Hyrax have FileSets attached to more than one Monograph/Work and we haven't had...
      # "intermediate" Works (a.k.a. "Sections") in a really long time. So grab the one and only parent *once* here.
      @monograph ||= object.in_works.first

      hidden_representative = false

      if @monograph.present?
        index_monograph_metadata(solr_doc)
        index_monograph_position(solr_doc)

        hidden_representative = true if @monograph.representative_id == object.id ||
          FeaturedRepresentative.where(work_id: @monograph.id, file_set_id: object.id)
                                .where.not(kind: ['database', 'webgl']).present? # these are weird oddball FeaturedRepresentatives that *do* appear in Blacklight results
      end

      if hidden_representative
        solr_doc['hidden_representative_bsi'] = true
      else
        # just remove it from the doc if this is not a cover or FeaturedRepresentative
        solr_doc['hidden_representative_bsi'] = nil
      end

      if object.sort_date.present?
        solr_doc['search_year_si'] = object.sort_date[0, 4]
        solr_doc['search_year_sim'] = object.sort_date[0, 4]
      end

      # HELIO-2428 index the "full" doi url if there's a doi
      solr_doc['doi_url_ssim'] = "https://doi.org/" + object.doi if object.doi.present?

      # HELIO-4739 - YouTube video embed codes
      maybe_index_youtube_metadata(solr_doc)
    end
  end

  def importable_backup_authorship_value(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r\n?|\n/).map(&:strip).reject(&:blank?).join('; ') : value
  end

  def multiline_names_minus_role(field)
    value = object.public_send(field).first
    value.present? ? value.split(/\r\n?|\n/).reject(&:blank?).map { |val| val.sub(/\s*\(.+\)$/, '').strip } : value
  end

  def multiline_contributors
    # any role in parenthesis will persist in Solr for contributors, as we've always done
    value = object.contributor.first
    value.present? ? value.split(/\r\n?|\n/).reject(&:blank?).map(&:strip) : value
  end

  def first_creator_roles # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    value = object.creator.first
    value.present? ? Array.wrap(value[/\(([^()]*)\)/]&.gsub(/\(|\)/, '')&.split(',')&.map(&:strip)&.map(&:downcase)) : value
  end

  def index_technical_metadata(solr_doc, orig) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    solr_doc['duration_ssim'] = orig.duration.first if orig.duration.present?
    solr_doc['sample_rate_ssim'] = orig.sample_rate if orig.sample_rate.present?
    solr_doc['original_checksum_ssim'] = orig.original_checksum if orig.original_checksum.present?
    # Force UTF-8 since original_name is ASCII-8BIT (for some reason) which shouldn't be in the index, HELIO-3983
    solr_doc['original_name_tesim'] = orig.original_name.dup.force_encoding("UTF-8") if orig.original_name.present?
    # generate_solr_document is first run in IngestJob where `orig.uri.to_s` will return a file URI but no file will ...
    # actually be available in Fedora at that point, hence `FileSet.find(solr_doc[:id])&.files&.present?`
    return unless orig&.original_name&.ends_with?('.gif') && FileSet.find(solr_doc[:id])&.files&.present? && MiniMagick::Image.open(orig&.uri&.to_s)&.frames&.count > 1
    solr_doc['animated_gif_bsi'] = true
  end

  # Make sure the asset is aware of its monograph
  def index_monograph_metadata(solr_doc)
    solr_doc['monograph_id_ssim'] = @monograph.id
  end

  def index_monograph_position(solr_doc)
    # avoid nil errors here on first pass of reindex_everything if parent not yet indexed
    return if @monograph.blank?
    fileset_order = @monograph.ordered_member_ids
    solr_doc['monograph_position_isi'] = fileset_order.index(object.id) if fileset_order.present?
  end

  def maybe_index_youtube_metadata(solr_doc)
    yt_data = YouTubeVideoInfoService.get_yt_video_data(object.id)

    if yt_data.present?
      solr_doc['youtube_id_tesi'] = yt_data['id']
      solr_doc['youtube_video_bsi'] = yt_data['id'].present?
      # this is used to force able player to be used when otherwise it would not, for testing purposes
      solr_doc['youtube_video_use_able_player_bsi'] = yt_data['use_able_player']
      # this will allow us to not use Able Player on videos that lack captions on YT, because of https://github.com/ableplayer/ableplayer/issues/554
      solr_doc['youtube_video_captions_on_yt_bsi'] = yt_data['captions_present']
      # using standard Hyrax height/width fields here, as they are already tied into embed code and presenter methods
      solr_doc['width_is'] = yt_data['width']
      solr_doc['height_is'] = yt_data['height']
    end
  end
end
