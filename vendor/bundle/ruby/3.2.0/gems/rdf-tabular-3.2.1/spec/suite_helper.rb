$:.unshift "."
require 'spec_helper'
require 'rdf/turtle'
require 'json/ld'
require 'open-uri'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    REMOTE_PATH = "http://www.w3.org/2013/csvw/"
    LOCAL_PATH = ::File.expand_path("../w3c-csvw", __FILE__) + '/'

    class << self
      alias_method :original_open_file, :open_file
    end

    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, **options, &block)
      case
      when filename_or_url.to_s =~ /^file:/
        path = filename_or_url.to_s[5..-1]
        Kernel.open(path.to_s, &block)
      when filename_or_url.to_s =~ %r{http://www.w3.org/ns/csvw/?}
        ::File.open(::File.expand_path("../../etc/csvw.jsonld", __FILE__), &block)
      when filename_or_url.to_s == "http://www.w3.org/.well-known/csvm"
        ::File.open(::File.expand_path("../../etc/well-known", __FILE__), &block)
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH}} && Dir.exist?(LOCAL_PATH))
        begin
          #puts "attempt to open #{filename_or_url} locally"
          localpath = RDF::URI(filename_or_url).dup
          localpath.query = nil
          localpath = localpath.to_s.sub(REMOTE_PATH, LOCAL_PATH)
          response = begin
            ::File.open(localpath)
          rescue Errno::ENOENT => e
            raise IOError, e.message
          end
          document_options = {
            base_uri:     RDF::URI(filename_or_url),
            charset:      Encoding::UTF_8,
            code:         200,
            headers:      {}
          }
          #puts "use #{filename_or_url} locally"
          document_options[:headers][:content_type] = case filename_or_url.to_s
          when /\.csv$/    then 'text/csv'
          when /\.tsv$/    then 'text/tsv'
          when /\.json$/   then 'application/json'
          when /\.jsonld$/ then 'application/ld+json'
          else                  'unknown'
          end

          document_options[:headers][:content_type] = response.content_type if response.respond_to?(:content_type)
          # For overriding content type from test data
          document_options[:headers][:content_type] = options[:contentType] if options[:contentType]

          # For overriding Link header from test data
          document_options[:headers][:link] = options[:httpLink] if options[:httpLink]

          remote_document = RDF::Util::File::RemoteDocument.new(response.read, document_options)
          if block_given?
            yield remote_document
          else
            remote_document
          end
        end
      else
        original_open_file(filename_or_url, **options) do |remote_document|
          # Add Link header, if necessary
          remote_document.headers[:link] = options[:httpLink] if options[:httpLink]

          # Override content_type
          if options[:contentType]
            remote_document.headers[:content_type] = options[:contentType]
            remote_document.instance_variable_set(:@content_type, options[:contentType].split(';').first)
          end

          if block_given?
            yield remote_document
          else
            remote_document
          end
        end
      end
    end
  end
end

module Fixtures
  module SuiteTest
    BASE = "http://www.w3.org/2013/csvw/tests/"
    class Manifest < JSON::LD::Resource
      def self.open(file, base)
        RDF::Util::File.open_file(file) do |file|
          json = ::JSON.load(file.read)
          yield Manifest.new(json, context: json['@context'].merge('@base' => base))
        end
      end

      def entries
        # Map entries to resources
        attributes['entries'].map {|e| Entry.new(e, context: context)}
      end
    end
 
    class Entry < JSON::LD::Resource
      attr_accessor :logger
      attr_accessor :warnings
      attr_accessor :errors
      attr_accessor :metadata

      def id
        attributes['id']
      end

      def base
        action
      end

      # Apply base to action and result
      def action
        RDF::URI(context['@base']).join(attributes["action"]).to_s
      end

      def result
        RDF::URI(context['@base']).join(attributes["result"]).to_s if attributes["result"]
      end

      def input
        @input ||= RDF::Util::File.open_file(action) {|f| f.read}
      end

      def expected
        @expected ||= RDF::Util::File.open_file(result) {|f| f.read} rescue nil
      end
      
      def evaluate?
        type.to_s.include?("To")
      end
      
      def rdf?
        result.to_s.end_with?(".ttl")
      end

      def json?
        result.to_s.end_with?(".json")
      end

      def validation?
        type.to_s.include?("Validation")
      end

      def warning?
        type.to_s.include?("Warning")
      end

      def positive_test?
        !negative_test?
      end
      
      def negative_test?
        type.to_s.include?("Negative")
      end

      def reader_options
        res = {}
        res[:noProv] = option['noProv'] if option
        res[:metadata] = RDF::URI(context['@base']).join(option['metadata']).to_s if option && option.has_key?('metadata')
        res[:httpLink] = httpLink if attributes['httpLink']
        res[:minimal] = option['minimal'] if option
        res[:contentType] = contentType if attributes['contentType']
        res
      end
    end
  end
end
