# frozen_string_literal: true
module DropboxApi::Metadata
  class CommitInfo < Base
    field :path, String
    field :mode, DropboxApi::Metadata::WriteMode, :optional
    field :autorename, :boolean, :optional
    field :client_modified, Time, :optional
    field :mute, :boolean, :optional

    class << self
      def build_from_options(options)
        options = Hash[options.map do |key, value|
          case key
          when :mode
            [key.to_s, build_write_mode(value)]
          when :client_modified
            [key.to_s, build_client_modified(value)]
          when :path, :autorename, :mute
            [key.to_s, value]
          end
        end.compact]

        new(options)
      end

      private

      def build_write_mode(write_mode)
        case write_mode
        when String, Symbol
          DropboxApi::Metadata::WriteMode.new write_mode
        when DropboxApi::Metadata::WriteMode
          write_mode
        else
          raise ArgumentError, "Invalid write mode: #{write_mode.inspect}"
        end.to_hash
      end

      def build_client_modified(client_modified)
        client_modified.utc.strftime('%FT%TZ')
      end
    end
  end
end
