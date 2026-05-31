# frozen_string_literal: true
module ActiveEncode
  module EngineAdapters
    class ZencoderAdapter
      # TODO: add a stub for an input helper (supplied by an initializer) that transforms encode.input.url into a zencoder accepted url
      def create(input_url, _options = {})
        response = Zencoder::Job.create(input: input_url.to_s)
        build_encode(get_job_details(response.body["id"]))
      end

      def find(id, _opts = {})
        build_encode(get_job_details(id))
      end

      def cancel(id)
        response = Zencoder::Job.cancel(id)
        build_encode(get_job_details(id)) if response.success?
      end

      private

        def get_job_details(job_id)
          Zencoder::Job.details(job_id)
        end

        def get_job_progress(job_id)
          Zencoder::Job.progress(job_id)
        end

        def build_encode(job_details)
          return nil if job_details.nil?
          encode = ActiveEncode::Base.new(convert_input(job_details), convert_options(job_details))
          encode.id = job_details.body["job"]["id"].to_s
          encode.state = convert_state(get_job_state(job_details))
          job_progress = get_job_progress(encode.id)
          encode.current_operations = convert_current_operations(job_progress)
          encode.percent_complete = convert_percent_complete(job_progress, job_details)
          encode.created_at = job_details.body["job"]["created_at"]
          encode.updated_at = job_details.body["job"]["updated_at"]
          encode.errors = []

          encode.output = convert_output(job_details, job_progress)

          encode.input.id = job_details.body["job"]["input_media_file"]["id"].to_s
          encode.input.errors = convert_input_errors(job_details)
          tech_md = convert_tech_metadata(job_details.body["job"]["input_media_file"])
          [:width, :height, :frame_rate, :duration, :checksum, :audio_codec, :video_codec,
           :audio_bitrate, :video_bitrate, :file_size].each do |field|
            encode.input.send("#{field}=", tech_md[field])
          end
          encode.input.state = convert_state(job_details.body["job"]["input_media_file"]["state"])
          encode.input.created_at = job_details.body["job"]["input_media_file"]["created_at"]
          encode.input.updated_at = job_details.body["job"]["input_media_file"]["updated_at"]

          encode
        end

        def convert_state(state)
          case state
          when "assigning", "pending", "waiting", "processing" # Should there be a queued state?
            :running
          when "cancelled"
            :cancelled
          when "failed", "no_input"
            :failed
          when "finished"
            :completed
          end
        end

        def get_job_state(job_details)
          job_details.body["job"]["state"]
        end

        def convert_current_operations(job_progress)
          current_ops = []
          job_progress.body["outputs"].each { |output| current_ops << output["current_event"] unless output["current_event"].nil? }
          current_ops
        end

        def convert_percent_complete(job_progress, job_details)
          percent = job_progress.body["progress"]
          percent ||= 100 if convert_state(get_job_state(job_details)) == :completed
          percent ||= 0
          percent
        end

        def convert_input(job_details)
          job_details.body["job"]["input_media_file"]["url"]
        end

        def convert_options(_job_details)
          {}
        end

        def convert_output(job_details, job_progress)
          job_details.body["job"]["output_media_files"].collect do |o|
            output = ActiveEncode::Output.new
            output.id = o["id"].to_s
            output.label = o["label"]
            output.url = o["url"]
            output.errors = Array(o["error_message"])

            tech_md = convert_tech_metadata(o)
            [:width, :height, :frame_rate, :duration, :checksum, :audio_codec, :video_codec,
             :audio_bitrate, :video_bitrate, :file_size].each do |field|
              output.send("#{field}=", tech_md[field])
            end
            output_progress = job_progress.body["outputs"].find { |out_prog| out_prog["id"] = output.id }
            output.state = convert_state(output_progress["state"])
            output.created_at = o["created_at"]
            output.updated_at = o["updated_at"]
            output
          end
        end

        def convert_input_errors(job_details)
          Array(job_details.body["job"]["input_media_file"]["error_message"])
        end

        def convert_tech_metadata(media_file)
          return {} if media_file.nil?

          metadata = {}
          media_file.each_pair do |key, value|
            next if value.blank?
            case key
            when "md5_checksum"
              metadata[:checksum] = value
            when "format"
              metadata[:mime_type] = value
            when "duration_in_ms"
              metadata[:duration] = value
            when "audio_codec"
              metadata[:audio_codec] = value
            when "channels"
              metadata[:audio_channels] = value
            when "audio_bitrate_in_kbps"
              metadata[:audio_bitrate] = value
            when "video_codec"
              metadata[:video_codec] = value
            when "frame_rate"
              metadata[:frame_rate] = value
            when "video_bitrate_in_kbps"
              metadata[:video_bitrate] = value
            when "width"
              metadata[:width] = value
            when "height"
              metadata[:height] = value
            end
          end
          metadata
        end
    end
  end
end
