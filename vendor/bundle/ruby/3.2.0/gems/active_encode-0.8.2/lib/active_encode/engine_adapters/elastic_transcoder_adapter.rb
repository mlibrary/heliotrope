# frozen_string_literal: true
require 'addressable/uri'
require 'aws-sdk-elastictranscoder'
require 'file_locator'

module ActiveEncode
  module EngineAdapters
    class ElasticTranscoderAdapter
      JOB_STATES = {
        "Submitted" => :running, "Progressing" => :running, "Canceled" => :cancelled,
        "Error" => :failed, "Complete" => :completed
      }.freeze

      # Require options to include :pipeline_id, :masterfile_bucket and :outputs
      # Example :outputs value:
      # [{ key: "quality-low/hls/fireworks", preset_id: '1494429796844-aza6zh', segment_duration: '2' },
      #  { key: "quality-medium/hls/fireworks", preset_id: '1494429797061-kvg9ki', segment_duration: '2' },
      #  { key: "quality-high/hls/fireworks", preset_id: '1494429797265-9xi831', segment_duration: '2' }]
      def create(input_url, options = {})
        s3_key = copy_to_input_bucket input_url, options[:masterfile_bucket]
        job = client.create_job(
          input: { key: s3_key },
          pipeline_id: options[:pipeline_id],
          output_key_prefix: options[:output_key_prefix] || "#{SecureRandom.uuid}/",
          outputs: options[:outputs],
          user_metadata: options[:user_metadata]
        ).job

        build_encode(job)
      end

      def find(id, _opts = {})
        build_encode(get_job_details(id))
      end

      # Can only cancel jobs with status = "Submitted"
      def cancel(id)
        response = client.cancel_job(id: id)
        build_encode(get_job_details(id)) if response.successful?
      end

      private

        # Needs region and credentials setup per http://docs.aws.amazon.com/sdkforruby/api/Aws/ElasticTranscoder/Client.html
        def client
          @client ||= Aws::ElasticTranscoder::Client.new
        end

        def s3client
          Aws::S3::Client.new
        end

        def get_job_details(job_id)
          client.read_job(id: job_id)&.job
        end

        def build_encode(job)
          return nil if job.nil?
          encode = ActiveEncode::Base.new(convert_input(job), {})
          encode.id = job.id
          encode.state = JOB_STATES[job.status]
          encode.current_operations = []
          encode.percent_complete = convert_percent_complete(job)
          encode.created_at = convert_time(job.timing["submit_time_millis"])
          encode.updated_at = convert_time(job.timing["finish_time_millis"]) || convert_time(job.timing["start_time_millis"]) || encode.created_at

          encode.output = convert_output(job)
          encode.errors = job.outputs.select { |o| o.status == "Error" }.collect(&:status_detail).compact

          tech_md = convert_tech_metadata(job.input.detected_properties)
          [:width, :height, :frame_rate, :duration, :file_size].each do |field|
            encode.input.send("#{field}=", tech_md[field])
          end

          encode.input.id = job.id
          encode.input.state = encode.state
          encode.input.created_at = encode.created_at
          encode.input.updated_at = encode.updated_at

          encode
        end

        def convert_time(time_millis)
          return nil if time_millis.nil?
          Time.at(time_millis / 1000).utc
        end

        def convert_bitrate(rate)
          return nil if rate.nil?
          (rate.to_f * 1024).to_s
        end

        def convert_state(job)
          case job.status
          when "Submitted", "Progressing" # Should there be a queued state?
            :running
          when "Canceled"
            :cancelled
          when "Error"
            :failed
          when "Complete"
            :completed
          end
        end

        def convert_percent_complete(job)
          job.outputs.inject(0) { |sum, output| sum + output_percentage(output) } / job.outputs.length
        end

        def output_percentage(output)
          case output.status
          when "Submitted"
            10
          when "Progressing", "Canceled", "Error"
            50
          when "Complete"
            100
          else
            0
          end
        end

        def convert_input(job)
          job.input.key
        end

        def copy_to_input_bucket(input_url, bucket)
          case Addressable::URI.parse(input_url).scheme
          when nil, 'file'
            upload_to_s3 input_url, bucket
          when 's3'
            check_s3_bucket input_url, bucket
          end
        end

        def check_s3_bucket(input_url, source_bucket)
          # logger.info("Checking `#{input_url}'")
          s3_object = FileLocator::S3File.new(input_url).object
          if s3_object.bucket_name == source_bucket
            # logger.info("Already in bucket `#{source_bucket}'")
            s3_object.key
          else
            s3_key = File.join(SecureRandom.uuid, s3_object.key)
            # logger.info("Copying to `#{source_bucket}/#{input_url}'")
            target = Aws::S3::Object.new(bucket_name: source_bucket, key: input_url)
            target.copy_from(s3_object, multipart_copy: s3_object.size > 15_728_640) # 15.megabytes
            s3_key
          end
        end

        def upload_to_s3(input_url, source_bucket)
          # original_input = input_url
          bucket = Aws::S3::Resource.new(client: s3client).bucket(source_bucket)
          filename = FileLocator.new(input_url).location
          s3_key = File.join(SecureRandom.uuid, File.basename(filename))
          # logger.info("Copying `#{original_input}' to `#{source_bucket}/#{input_url}'")
          obj = bucket.object(s3_key)
          obj.upload_file filename

          s3_key
        end

        def read_preset(id)
          @presets ||= {}
          @presets[id] ||= client.read_preset(id: id).preset
        end

        def convert_output(job)
          @pipeline ||= client.read_pipeline(id: job.pipeline_id).pipeline
          job.outputs.collect do |joutput|
            preset = read_preset(joutput.preset_id)
            extension = preset.container == 'ts' ? '.m3u8' : ''
            additional_metadata = {
              managed: false,
              id: joutput.id,
              label: joutput.key.split("/", 2).first,
              url: "s3://#{@pipeline.output_bucket}/#{job.output_key_prefix}#{joutput.key}#{extension}"
            }
            tech_md = convert_tech_metadata(joutput, preset).merge(additional_metadata)

            output = ActiveEncode::Output.new
            output.state = convert_state(joutput)
            output.created_at = convert_time(job.timing["submit_time_millis"])
            output.updated_at = convert_time(job.timing["finish_time_millis"] || job.timing["start_time_millis"]) || output.created_at

            [:width, :height, :frame_rate, :duration, :checksum, :audio_codec, :video_codec,
             :audio_bitrate, :video_bitrate, :file_size, :label, :url, :id].each do |field|
              output.send("#{field}=", tech_md[field])
            end

            output
          end
        end

        def convert_errors(job)
          job.outputs.select { |o| o.status == "Error" }.collect(&:status_detail).compact
        end

        def convert_tech_metadata(props, preset = nil)
          return {} if props.nil? || props.empty?
          metadata_fields = {
            file_size: { key: :file_size, method: :itself },
            duration_millis: { key: :duration, method: :to_i },
            frame_rate: { key: :frame_rate, method: :to_i },
            segment_duration: { key: :segment_duration, method: :itself },
            width: { key: :width, method: :itself },
            height: { key: :height, method: :itself }
          }

          metadata = {}
          props.each_pair do |key, value|
            next if value.nil?
            conversion = metadata_fields[key.to_sym]
            next if conversion.nil?
            metadata[conversion[:key]] = value.send(conversion[:method])
          end

          unless preset.nil?
            audio = preset.audio
            video = preset.video
            metadata.merge!(
              audio_codec: audio&.codec,
              audio_channels: audio&.channels,
              audio_bitrate: convert_bitrate(audio&.bit_rate),
              video_codec: video&.codec,
              video_bitrate: convert_bitrate(video&.bit_rate)
            )
          end

          metadata
        end
    end
  end
end
