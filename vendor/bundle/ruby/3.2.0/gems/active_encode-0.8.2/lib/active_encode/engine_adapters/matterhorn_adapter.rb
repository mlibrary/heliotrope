# frozen_string_literal: true
require 'rubyhorn'

module ActiveEncode
  module EngineAdapters
    class MatterhornAdapter
      DEFAULT_ARGS = { 'flavor' => 'presenter/source' }.freeze

      def create(input_url, options = {})
        workflow_id = options[:preset] || "full"
        workflow_om = Rubyhorn.client.addMediaPackageWithUrl(DEFAULT_ARGS.merge('workflow' => workflow_id, 'url' => input_url, 'filename' => File.basename(input_url), 'title' => File.basename(input_url)))
        build_encode(get_workflow(workflow_om))
      end

      def find(id, _opts = {})
        build_encode(fetch_workflow(id))
      end

      def cancel(id)
        workflow_om = Rubyhorn.client.stop(id)
        build_encode(get_workflow(workflow_om))
      end

      private

        def fetch_workflow(id)
          workflow_om = begin
            Rubyhorn.client.instance_xml(id)
          rescue Rubyhorn::RestClient::Exceptions::HTTPNotFound
            nil
          end

          workflow_om ||= begin
            Rubyhorn.client.get_stopped_workflow(id)
          rescue
            nil
          end

          get_workflow(workflow_om)
        end

        def get_workflow(workflow_om)
          return nil if workflow_om.nil?
          if workflow_om.ng_xml.is_a? Nokogiri::XML::Document
            workflow_om.ng_xml.remove_namespaces!.root
          else
            workflow_om.ng_xml
          end
        end

        def build_encode(workflow)
          return nil if workflow.nil?
          input_url = convert_input(workflow)
          input_url = get_workflow_title(workflow) if input_url.blank?
          encode = ActiveEncode::Base.new(input_url, convert_options(workflow))
          encode.id = convert_id(workflow)
          encode.state = convert_state(workflow)
          encode.current_operations = convert_current_operations(workflow)
          encode.percent_complete = calculate_percent_complete(workflow)
          encode.created_at = convert_created_at(workflow)
          encode.updated_at = convert_updated_at(workflow) || encode.created_at
          encode.output = convert_output(workflow, encode.options)
          encode.errors = convert_errors(workflow)

          encode.input.id = "presenter/source"
          encode.input.state = encode.state
          encode.input.created_at = encode.created_at
          encode.input.updated_at = encode.updated_at
          tech_md = convert_tech_metadata(workflow)
          [:width, :height, :duration, :frame_rate, :checksum, :audio_codec, :video_codec,
           :audio_bitrate, :video_bitrate].each do |field|
            encode.input.send("#{field}=", tech_md[field])
          end

          encode
        end

        def convert_id(workflow)
          workflow.attribute('id').to_s
        end

        def get_workflow_state(workflow)
          workflow.attribute('state').to_s
        end

        def convert_state(workflow)
          case get_workflow_state(workflow)
          when "INSTANTIATED", "RUNNING" # Should there be a queued state?
            :running
          when "STOPPED"
            :cancelled
          when "FAILED"
            workflow.xpath('//operation[@state="FAILED"]').empty? ? :cancelled : :failed
          when "SUCCEEDED", "SKIPPED" # Should there be a errored state?
            :completed
          end
        end

        def convert_input(workflow)
          # Need to do anything else since this is a MH url? and this disappears when a workflow is cleaned up
          workflow.xpath('mediapackage/media/track[@type="presenter/source"]/url/text()').to_s.strip
        end

        def get_workflow_title(workflow)
          workflow.xpath('mediapackage/title/text()').to_s.strip
        end

        def convert_tech_metadata(workflow)
          convert_track_metadata(workflow.xpath('//track[@type="presenter/source"]').first)
        end

        def convert_output(workflow, options)
          outputs = []
          workflow.xpath('//track[@type="presenter/delivery" and tags/tag[text()="streaming"]]').each do |track|
            output = ActiveEncode::Output.new
            output.label = track.xpath('tags/tag[starts-with(text(),"quality")]/text()').to_s
            output.url = track.at("url/text()").to_s
            if output.url.start_with? "rtmp"
              output.url = File.join(options[:stream_base], MatterhornRtmpUrl.parse(output.url).to_path) if options[:stream_base]
            end
            output.id = track.at("@id").to_s

            tech_md = convert_track_metadata(track)
            [:width, :height, :frame_rate, :duration, :checksum, :audio_codec, :video_codec,
             :audio_bitrate, :video_bitrate, :file_size].each do |field|
              output.send("#{field}=", tech_md[field])
            end

            output.state = :completed
            output.created_at = convert_output_created_at(track, workflow)
            output.updated_at = convert_output_updated_at(track, workflow)

            outputs << output
          end
          outputs
        end

        def convert_current_operations(workflow)
          current_op = workflow.xpath('//operation[@state!="INSTANTIATED"]/@description').last.to_s
          current_op.present? ? [current_op] : []
        end

        def convert_errors(workflow)
          workflow.xpath('//errors/error/text()').map(&:to_s)
        end

        def convert_created_at(workflow)
          created_at = workflow.xpath('mediapackage/@start').last.to_s
          created_at.present? ? Time.parse(created_at).utc : nil
        end

        def convert_updated_at(workflow)
          updated_at = workflow.xpath('//operation[@state!="INSTANTIATED"]/completed/text()').last.to_s
          updated_at.present? ? Time.strptime(updated_at, "%Q") : nil
        end

        def convert_output_created_at(track, workflow)
          quality = track.xpath('tags/tag[starts-with(text(),"quality")]/text()').to_s
          created_at = workflow.xpath("//operation[@id=\"compose\"][configurations/configuration[@key=\"target-tags\" and contains(text(), \"#{quality}\")]]/started/text()").to_s
          created_at.present? ? Time.at(created_at.to_i / 1000.0).utc : nil
        end

        def convert_output_updated_at(track, workflow)
          quality = track.xpath('tags/tag[starts-with(text(),"quality")]/text()').to_s
          updated_at = workflow.xpath("//operation[@id=\"compose\"][configurations/configuration[@key=\"target-tags\" and contains(text(), \"#{quality}\")]]/completed/text()").to_s
          updated_at.present? ? Time.at(updated_at.to_i / 1000.0).utc : nil
        end

        def convert_options(workflow)
          options = {}
          options[:preset] = workflow.xpath('template/text()').to_s
          options[:stream_base] = workflow.xpath('//properties/property[@key="avalon.stream_base"]/text()').to_s if workflow.xpath('//properties/property[@key="avalon.stream_base"]/text()').present? # this is avalon-felix specific
          options
        end

        def convert_track_metadata(track)
          return {} if track.nil?
          metadata = {}
          # metadata[:mime_type] = track.at("mimetype/text()").to_s if track.at('mimetype')
          metadata[:checksum] = track.at("checksum/text()").to_s.strip if track.at('checksum')
          metadata[:duration] = track.at("duration/text()").to_s.to_i if track.at('duration')
          if track.at('audio')
            metadata[:audio_codec] = track.at("audio/encoder/@type").to_s
            metadata[:audio_channels] = track.at("audio/channels/text()").to_s
            metadata[:audio_bitrate] = track.at("audio/bitrate/text()").to_s.to_f
          end
          if track.at('video')
            metadata[:video_codec] = track.at("video/encoder/@type").to_s
            metadata[:video_bitrate] = track.at("video/bitrate/text()").to_s.to_f
            metadata[:frame_rate] = track.at("video/framerate/text()").to_s.to_f
            metadata[:width] = track.at("video/resolution/text()").to_s.split('x')[0].to_i
            metadata[:height] = track.at("video/resolution/text()").to_s.split('x')[1].to_i
          end
          metadata
        end

        def get_media_package(workflow)
          mp = workflow.xpath('//mediapackage')
          first_node = mp.first
          first_node['xmlns'] = 'http://mediapackage.opencastproject.org'
          mp
        end

        def calculate_percent_complete(workflow)
          totals = {
            transcode: 70,
            distribution: 20,
            other: 10
          }

          completed_transcode_operations = workflow.xpath('//operation[@id="compose" and (@state="SUCCEEDED" or @state="SKIPPED")]').size
          total_transcode_operations = workflow.xpath('//operation[@id="compose"]').size
          total_transcode_operations = 1 if total_transcode_operations.zero?
          completed_distribution_operations = workflow.xpath('//operation[starts-with(@id,"distribute") and (@state="SUCCEEDED" or @state="SKIPPED")]').size
          total_distribution_operations = workflow.xpath('//operation[starts-with(@id,"distribute")]').size
          total_distribution_operations = 1 if total_distribution_operations.zero?
          completed_other_operations = workflow.xpath('//operation[@id!="compose" and not(starts-with(@id,"distribute")) and (@state="SUCCEEDED" or @state="SKIPPED")]').size
          total_other_operations = workflow.xpath('//operation[@id!="compose" and not(starts-with(@id,"distribute"))]').size
          total_other_operations = 1 if total_other_operations.zero?

          ((totals[:transcode].to_f / total_transcode_operations) * completed_transcode_operations) +
            ((totals[:distribution].to_f / total_distribution_operations) * completed_distribution_operations) +
            ((totals[:other].to_f / total_other_operations) * completed_other_operations)
        end

        def create_multiple_files(input, workflow_id)
          # Create empty media package xml document
          mp = Rubyhorn.client.createMediaPackage

          # Next line associates workflow title to avalon via masterfile pid
          title = File.basename(input.values.first)
          dc = Nokogiri::XML('<dublincore xmlns="http://www.opencastproject.org/xsd/1.0/dublincore/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dcterms:title>' + title + '</dcterms:title></dublincore>')
          mp = Rubyhorn.client.addDCCatalog('mediaPackage' => mp.to_xml, 'dublinCore' => dc.to_xml, 'flavor' => 'dublincore/episode')

          # Add quality levels - repeated for each supplied file url
          input.each_pair do |quality, url|
            mp = Rubyhorn.client.addTrack('mediaPackage' => mp.to_xml, 'url' => url, 'flavor' => DEFAULT_ARGS['flavor'])
            # Rewrite track to include quality tag
            # Get the empty tags element under the newly added track
            tags = mp.xpath('//xmlns:track/xmlns:tags[not(node())]', 'xmlns' => 'http://mediapackage.opencastproject.org').first
            quality_tag = Nokogiri::XML::Node.new 'tag', mp
            quality_tag.content = quality
            tags.add_child quality_tag
          end
          # Finally ingest the media package
          begin
                  Rubyhorn.client.start("definitionId" => workflow_id, "mediapackage" => mp.to_xml)
                rescue Rubyhorn::RestClient::Exceptions::HTTPBadRequest
                  # make this two calls...one to get the workflow definition xml and then the second to submit it along with the mediapackage to start...due to unsolved issue with some MH installs
                  begin
                          workflow_definition_xml = Rubyhorn.client.definition_xml(workflow_id)
                          Rubyhorn.client.start("definition" => workflow_definition_xml, "mediapackage" => mp.to_xml)
                        rescue Rubyhorn::RestClient::Exceptions::HTTPNotFound
                          raise StandardError, "Unable to start workflow"
                        end
                end
        end
    end

    class MatterhornRtmpUrl
      class_attribute :members
      self.members = %i[application prefix media_id stream_id filename extension]
      attr_accessor(*members)
      REGEX = %r{^
  /(?<application>.+)        # application (avalon)
  /(?:(?<prefix>.+):)?       # prefix      (mp4:)
  (?<media_id>[^\/]+)        # media_id    (98285a5b-603a-4a14-acc0-20e37a3514bb)
  /(?<stream_id>[^\/]+)      # stream_id   (b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3)
  /(?<filename>.+?)          # filename    (MVI_0057)
  (?:\.(?<extension>.+))?$   # extension   (mp4)
      }x

      # @param [MatchData] match_data
      def initialize(match_data)
        self.class.members.each do |key|
          send("#{key}=", match_data[key])
        end
      end

      def self.parse(url_string)
        # Example input: /avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4

        uri = URI.parse(url_string)
        match_data = REGEX.match(uri.path)
        MatterhornRtmpUrl.new match_data
      end

      alias _binding binding
      def binding
        _binding
      end

      def to_path
        File.join(media_id, stream_id, "#{filename}.#{extension || prefix}")
      end
    end
  end
end
