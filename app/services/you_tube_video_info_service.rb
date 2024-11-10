# frozen_string_literal: true

class YouTubeVideoInfoService
  def self.get_yt_video_data(file_set_id)
    data = {}
    @file_set = FileSet.find(file_set_id)
    @use_able_player_id = able_player_youtube_id
    @yt_id = @use_able_player_id || youtube_id

    if @yt_id.present?
      oembed_data(data)
      # we'll assume the video doesn't exist if there was no good response from oembed, just a cleaner existence...
      # check than using the insanely-complicated video landing page
      return nil if data.blank?
      data['id'] = @yt_id
      data['use_able_player'] = @use_able_player_id.present?
      analyse_yt_page(data)
    else
      # not a "YT video" FileSet
      return nil
    end
    data
  end

  def self.youtube_id
    @file_set.identifier&.find { |i| i[/^youtube_id:.*/] }&.gsub('youtube_id:', '')&.strip
  end

  # this thing was originally planned to allow an editor to *choose* which player they want to use. That's not...
  # really an option given that Able Player has serious issues with YT videos, most notably this one:
  # https://github.com/ableplayer/ableplayer/issues/554
  # but I'm leaving this in as a tool to force the use of Able Player for testing purposes
  def self.able_player_youtube_id
    @file_set.identifier&.find { |i| i[/^able_player_youtube_id:.*/] }&.gsub('able_player_youtube_id:', '')&.strip
  end

  def self.oembed_data(data)
    url = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=#{@yt_id}&format=json"
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      oembed_info = JSON.parse(response.body)
      oembed_required_viewer_width = oembed_info['width'].to_i
      oembed_required_viewer_height = oembed_info['height'].to_i

      # Initially setting dimensions to 5x the oembed values, which are really only dimensions required to...
      # display the HTML (i.e. minimum dimensions for the embedded player). See https://oembed.com/#section2
      # Going with 5x as, historically, "width" (actual, known video width for a locally-hosted video) is used as...
      # `maxwidth` on video embed codes, and the oembed "minimum player width" value is too small for that.
      # We'll try to glean a better value from the YT page itself later.
      data['width'] = oembed_required_viewer_width * 5
      data['height'] = oembed_required_viewer_height * 5
    end
  end

  def self.analyse_yt_page(data)
    url = "https://www.youtube.com/watch?v=#{@yt_id}"
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data['captions_present'] = response.body.include?('"playerCaptionsTracklistRenderer":{"captionTracks":[{"baseUrl":')

      document = Nokogiri::HTML.parse(response.body)
      og_width = document.at_css('meta[property="og:video:width"]')
      data['width'] = og_width['content'].to_i if og_width.present? && og_width['content'].present?
      og_height = document.at_css('meta[property="og:video:height"]')
      data['height'] = og_height['content'].to_i if og_height.present? && og_height['content'].present?
    end
  end
end
