# frozen_string_literal: true
require 'active_encode/engine_adapters/media_convert_output.rb'
require 'active_support/core_ext/integer/time'
require 'addressable/uri'
require 'aws-sdk-cloudwatchevents'
require 'aws-sdk-cloudwatchlogs'
require 'aws-sdk-mediaconvert'
require 'file_locator'

require 'active_support/json'
require 'active_support/time'

module ActiveEncode
  module EngineAdapters
    class MediaConvertAdapter
      # [AWS Elemental MediaConvert](https://aws.amazon.com/mediaconvert/) doesn't provide detailed
      # output information in the job description that can be pulled directly from the service.
      # Instead, it provides that information along with the job status notification when the job
      # status changes to `COMPLETE`. The only way to capture that notification is through an [Amazon
      # Eventbridge](https://aws.amazon.com/eventbridge/) rule that forwards the status change
      # notification to another service for capture and/or handling.
      #
      # `ActiveEncode::EngineAdapters::MediaConvert` does this by creating a [CloudWatch Logs]
      # (https://aws.amazon.com/cloudwatch/) log group and an EventBridge rule to forward status
      # change notifications to the log group. It can then find the log entry containing the output
      # details later when the job is complete. This is accomplished by calling the idempotent
      # `#setup!` method.
      #
      # The AWS user/role calling the `#setup!` method will require permissions to create the
      # necessary CloudWatch and EventBridge resources, and the role passed to the engine adapter
      # will need access to any S3 buckets where files will be read from or written to during
      # transcoding.
      #
      # Configuration example:
      #
      #     ActiveEncode::Base.engine_adapter = :media_convert
      #     ActiveEncode::Base.engine_adapter.role = 'arn:aws:iam::123456789012:role/service-role/MediaConvert_Default_Role'
      #     ActiveEncode::Base.engine_adapter.output_bucket = 'output-bucket'
      #     ActiveEncode::Base.engine_adapter.setup!

      JOB_STATES = {
        "SUBMITTED" => :running, "PROGRESSING" => :running, "CANCELED" => :cancelled,
        "ERROR" => :failed, "COMPLETE" => :completed
      }.freeze

      OUTPUT_GROUP_TEMPLATES = {
        hls: { min_segment_length: 0, segment_control: "SEGMENTED_FILES", segment_length: 10 },
        dash_iso: { fragment_length: 2, segment_control: "SEGMENTED_FILES", segment_length: 30 },
        file: {},
        ms_smooth: { fragment_length: 2 },
        cmaf: { fragment_length: 2, segment_control: "SEGMENTED_FILES", segment_length: 10 }
      }.freeze

      class ResultsNotAvailable < RuntimeError
        attr_reader :encode

        def initialize(msg = nil, encode = nil)
          @encode = encode
          super(msg)
        end
      end

      attr_accessor :role, :output_bucket
      attr_writer :log_group, :queue

      def setup!
        rule_name = "active-encode-mediaconvert-#{queue}"
        return true if event_rule_exists?(rule_name)

        queue_arn = mediaconvert.get_queue(name: queue).queue.arn

        event_pattern = {
          source: ["aws.mediaconvert"],
          "detail-type": ["MediaConvert Job State Change"],
          detail: {
            queue: [queue_arn]
          }
        }

        log_group_arn = create_log_group(log_group).arn

        cloudwatch_events.put_rule(
          name: rule_name,
          event_pattern: event_pattern.to_json,
          state: "ENABLED",
          description: "Forward MediaConvert job state changes from queue #{queue} to #{log_group}"
        )

        cloudwatch_events.put_targets(
          rule: rule_name,
          targets: [
            {
              id: "Id#{SecureRandom.uuid}",
              arn: log_group_arn
            }
          ]
        )
        true
      end

      # Required options:
      #
      # * `output_prefix`: The S3 key prefix to use as the base for all outputs.
      #
      # * `outputs`: An array of `{preset, modifier}` options defining how to transcode and name the outputs.
      #
      # Optional options:
      #
      # * `masterfile_bucket`: The bucket to which file-based inputs will be copied before
      #                        being passed to MediaConvert. Also used for S3-based inputs
      #                        unless `use_original_url` is specified.
      #
      # * `use_original_url`: If `true`, any S3 URL passed in as input will be passed directly to
      #                       MediaConvert as the file input instead of copying the source to
      #                       the `masterfile_bucket`.
      #
      # Example:
      # {
      #   output_prefix: "path/to/output/files",
      #   outputs: [
      #       {preset: "System-Avc_16x9_1080p_29_97fps_8500kbps", modifier: "-1080"},
      #       {preset: "System-Avc_16x9_720p_29_97fps_5000kbps", modifier: "-720"},
      #       {preset: "System-Avc_16x9_540p_29_97fps_3500kbps", modifier: "-540"}
      #     ]
      #   }
      # }
      def create(input_url, options = {})
        input_url = s3_uri(input_url, options)

        input = options[:media_type] == :audio ? make_audio_input(input_url) : make_video_input(input_url)

        create_job_params = {
          queue: queue,
          role: role,
          settings: {
            inputs: [input],
            output_groups: make_output_groups(options)
          }
        }

        response = mediaconvert.create_job(create_job_params)
        job = response.job
        build_encode(job)
      end

      def find(id, _opts = {})
        response = mediaconvert.get_job(id: id)
        job = response.job
        build_encode(job)
      rescue Aws::MediaConvert::Errors::NotFound
        raise ActiveEncode::NotFound, "Job #{id} not found"
      end

      def cancel(id)
        mediaconvert.cancel_job(id: id)
        find(id)
      end

      def log_group
        @log_group ||= "/aws/events/active-encode/mediaconvert/#{queue}"
      end

      def queue
        @queue ||= "Default"
      end

      private

        def build_encode(job)
          return nil if job.nil?
          encode = ActiveEncode::Base.new(job.settings.inputs.first.file_input, {})
          encode.id = job.id
          encode.input.id = job.id
          encode.state = JOB_STATES[job.status]
          encode.current_operations = [job.current_phase].compact
          encode.created_at = job.timing.submit_time
          encode.updated_at = job.timing.finish_time || job.timing.start_time || encode.created_at
          encode.percent_complete = convert_percent_complete(job)
          encode.errors = [job.error_message].compact
          encode.output = []

          encode.input.created_at = encode.created_at
          encode.input.updated_at = encode.updated_at

          encode = complete_encode(encode, job) if encode.state == :completed
          encode
        end

        def complete_encode(encode, job)
          result = convert_output(job)
          if result.nil?
            raise ResultsNotAvailable.new("Unable to load progress for job #{job.id}", encode) if job.timing.finish_time < 10.minutes.ago
            encode.state = :running
          else
            encode.output = result
          end
          encode
        end

        def convert_percent_complete(job)
          case job.status
          when "SUBMITTED"
            5
          when "PROGRESSING"
            job.job_percent_complete
          when "CANCELED", "ERROR"
            50
          when "COMPLETE"
            100
          else
            0
          end
        end

        def convert_output(job)
          results = get_encode_results(job)
          return nil if results.nil?
          convert_encode_results(job, results)
        end

        def convert_encode_results(job, results)
          settings = job.settings.output_groups.first.outputs

          outputs = results.dig('detail', 'outputGroupDetails', 0, 'outputDetails').map.with_index do |detail, index|
            tech_md = MediaConvertOutput.tech_metadata(settings[index], detail)
            output = ActiveEncode::Output.new

            output.created_at = job.timing.submit_time
            output.updated_at = job.timing.finish_time || job.timing.start_time || output.created_at

            [:width, :height, :frame_rate, :duration, :checksum, :audio_codec, :video_codec,
             :audio_bitrate, :video_bitrate, :file_size, :label, :url, :id].each do |field|
              output.send("#{field}=", tech_md[field])
            end
            output.id ||= "#{job.id}-output#{tech_md[:suffix]}"
            output
          end

          adaptive_playlist = results.dig('detail', 'outputGroupDetails', 0, 'playlistFilePaths', 0)
          unless adaptive_playlist.nil?
            output = ActiveEncode::Output.new
            output.created_at = job.timing.submit_time
            output.updated_at = job.timing.finish_time || job.timing.start_time || output.created_at
            output.id = "#{job.id}-output-auto"

            [:duration, :audio_codec, :video_codec].each do |field|
              output.send("#{field}=", outputs.first.send(field))
            end
            output.label = File.basename(adaptive_playlist)
            output.url = adaptive_playlist
            outputs << output
          end
          outputs
        end

        def get_encode_results(job)
          start_time = job.timing.submit_time
          end_time = (job.timing.finish_time || Time.now.utc) + 10.minutes

          response = cloudwatch_logs.start_query(
            log_group_name: log_group,
            start_time: start_time.to_i,
            end_time: end_time.to_i,
            limit: 1,
            query_string: "fields @message | filter detail.jobId = '#{job.id}' | filter detail.status = 'COMPLETE' | sort @ingestionTime desc"
          )
          query_id = response.query_id
          response = cloudwatch_logs.get_query_results(query_id: query_id)
          until response.status == "Complete"
            sleep(0.5)
            response = cloudwatch_logs.get_query_results(query_id: query_id)
          end

          return nil if response.results.empty?

          JSON.parse(response.results.first.first.value)
        end

        def cloudwatch_events
          @cloudwatch_events ||= Aws::CloudWatchEvents::Client.new
        end

        def cloudwatch_logs
          @cloudwatch_logs ||= Aws::CloudWatchLogs::Client.new
        end

        def mediaconvert
          endpoint = Aws::MediaConvert::Client.new.describe_endpoints.endpoints.first.url
          @mediaconvert ||= Aws::MediaConvert::Client.new(endpoint: endpoint)
        end

        def s3_uri(url, options = {})
          bucket = options[:masterfile_bucket]

          case Addressable::URI.parse(url).scheme
          when nil, 'file'
            upload_to_s3 url, bucket
          when 's3'
            return url if options[:use_original_url]
            check_s3_bucket url, bucket
          else
            raise ArgumentError, "Cannot handle source URL: #{url}"
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

        def event_rule_exists?(rule_name)
          rule = cloudwatch_events.list_rules(name_prefix: rule_name).rules.find do |existing_rule|
            existing_rule.name == rule_name
          end
          !rule.nil?
        end

        def find_log_group(name)
          cloudwatch_logs.describe_log_groups(log_group_name_prefix: name).log_groups.find do |group|
            group.log_group_name == name
          end
        end

        def create_log_group(name)
          result = find_log_group(name)

          return result unless result.nil?

          cloudwatch_logs.create_log_group(log_group_name: name)
          find_log_group(name)
        end

        def make_audio_input(input_url)
          {
            audio_selectors: { "Audio Selector 1" => { default_selection: "DEFAULT" } },
            audio_selector_groups: {
              "Audio Selector Group 1" => {
                audio_selector_names: ["Audio Selector 1"]
              }
            },
            file_input: input_url,
            timecode_source: "ZEROBASED"
          }
        end

        def make_video_input(input_url)
          {
            audio_selectors: { "Audio Selector 1" => { default_selection: "DEFAULT" } },
            file_input: input_url,
            timecode_source: "ZEROBASED",
            video_selector: {}
          }
        end

        def make_output_groups(options)
          output_type = options[:output_type] || :hls
          raise ArgumentError, "Unknown output type: #{output_type.inspect}" unless OUTPUT_GROUP_TEMPLATES.keys.include?(output_type)
          output_group_settings_key = "#{output_type}_group_settings".to_sym
          output_group_settings = OUTPUT_GROUP_TEMPLATES[output_type].merge(destination: "s3://#{output_bucket}/#{options[:output_prefix]}")

          outputs = options[:outputs].map do |output|
            {
              preset: output[:preset],
              name_modifier: output[:modifier]
            }
          end

          [{
            output_group_settings: {
              type: output_group_settings_key.upcase,
              output_group_settings_key => output_group_settings
            },
            outputs: outputs
          }]
        end
    end
  end
end
