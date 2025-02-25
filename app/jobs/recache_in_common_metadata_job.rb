# frozen_string_literal: true

require 'open3'

class RecacheInCommonMetadataJob < ApplicationJob
  INCOMMON_XML_FILE = File.join(Settings.scratch_space_path, 'InCommon-metadata.xml')
  INCOMMON_DOWNLOAD_CMD = "curl --silent http://metadata.ukfederation.org.uk/ukfederation-metadata.xml > #{INCOMMON_XML_FILE}"
  OPENATHENS_XML_FILE = File.join(Settings.scratch_space_path, 'OpenAthens-metadata.xml')
  OPENATHENS_DOWNLOAD_CMD = "curl --silent http://fed.openathens.net/oafed/metadata > #{OPENATHENS_XML_FILE}"
  RAILS_CACHE_KEY = 'federated-shib-metadata'
  JSON_FILE = File.join(Settings.scratch_space_path, "federated-shib-metadata.json")

  EntityDescriptor = Struct.new(:es) do
    def to_json # rubocop:disable Metrics/CyclomaticComplexity
      descriptions = []
      display_names = []
      information_urls = []
      logos = []
      privacy_statement_urls = []
      ue = uiinfo(es)
      if ue.present?
        ue.elements.each do |e|
          case e.name
          when /Description/i
            descriptions << value_lang_hash(e)
          when /DisplayName/i
            display_names << value_lang_hash(e)
          when /InformationURL/i
            information_urls << value_lang_hash(e)
          when /Logo/i
            logos << value_height_width_lang_hash(e)
          when /PrivacyStatementURL/i
            privacy_statement_urls << value_lang_hash(e)
          end
        end
      end
      hash = { "entityID" => es.attributes['entityID'].value }
      hash["Descriptions"] = descriptions
      hash["DisplayNames"] = display_names
      hash["InformationURLs"] = information_urls
      hash["Logos"] = logos
      hash["PrivacyStatementURLs"] = privacy_statement_urls
      hash.to_json
    end

    private

      def uiinfo(element)
        rvalue = nil
        case element.name
        when /UIInfo/i
          rvalue = element
        else
          element.elements.each do |e|
            rvalue ||= uiinfo(e)
          end
        end
        rvalue
      end

      def value_lang_hash(element)
        { "value" => element.content, "lang" => element.attributes['lang']&.value || 'en' }
      end

      def value_height_width_lang_hash(element)
        { "value" => element.content, "height" => element.attributes['height']&.value, "width" => element.attributes['width']&.value, "lang" => element.attributes['lang']&.value || 'en' }
      end
  end

  def perform
    return false unless download_xml
    return false unless parse_xml
    return false unless cache_json
    return false unless in_common
    true
  end

  def download_xml
    rvalue = true
    [INCOMMON_DOWNLOAD_CMD, OPENATHENS_DOWNLOAD_CMD].each do |command|
      Rails.logger.info("Running '#{command}'")
      stdin, stdout, stderr, wait_thr = Open3.popen3(command)
      stdin.close
      stdout.close
      err = stderr.read
      stderr.close

      if wait_thr.value.success?
        rvalue = true
      else
        Rails.logger.error("ERROR Command #{command} error #{err}")
        return false
      end
    end

    rvalue
  end

  def parse_xml
    first = true
    File.open(JSON_FILE, 'w') do |file| # rubocop:disable Metrics/BlockLength
      file << "[\n"

      xml_file = INCOMMON_XML_FILE
      if File.exist?(xml_file)
        Rails.logger.info("Parsing #{xml_file}")
        Nokogiri::XML::Reader(File.open(xml_file)).each do |node|
          if node.name == 'EntityDescriptor' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            file << ",\n" unless first
            file << EntityDescriptor.new(Nokogiri::XML(node.outer_xml).at('EntityDescriptor')).to_json
            first = false
          end
        end
      end

      # open athens is different apparently I don't know why
      xml_file = OPENATHENS_XML_FILE
      if File.exist?(xml_file)
        Rails.logger.info("Parsing #{xml_file}")
        Nokogiri::XML::Reader(File.open(xml_file)).each do |node|
          if node.name == 'md:EntitiesDescriptor'
            node.each do |n|
              if n.name == 'md:EntityDescriptor' && n.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
                file << ",\n" unless first
                file << EntityDescriptor.new(Nokogiri::XML(n.outer_xml).remove_namespaces!.at('EntityDescriptor')).to_json
                first = false
              end
            end
          end
        end
      end

      file << "\n]\n"
    end
    true
  end

  def load_json
    rvalue = []
    if File.exist?(JSON_FILE)
      begin
        rvalue = File.open(JSON_FILE, 'r') do |file|
                   JSON.load file || []
                 end
      rescue StandardError => e
        Rails.logger.error("ERROR: RecacheInCommonMetadataJob#load_json raised #{e}")
      end
    end
    rvalue
  end

  def cache_json
    Rails.cache.write(RAILS_CACHE_KEY, load_json, expires_in: 24.hours)
    true
  end

  def in_common
    return false unless File.exist?(RecacheInCommonMetadataJob::JSON_FILE)

    Greensub::Institution.update_all(in_common: false) # rubocop:disable Rails/SkipsModelValidations
    entity_ids = Set.new(Greensub::Institution.where("entity_id <> ''").map(&:entity_id))

    if entity_ids.present?
      load_json.each do |entry|
        next unless entry["entityID"].in?(entity_ids)

        institutions = Greensub::Institution.where(entity_id: entry["entityID"])
        institutions.each do |institution|
          institution.in_common = true
          institution.save!
        end
      end
    end
    true
  end
end
