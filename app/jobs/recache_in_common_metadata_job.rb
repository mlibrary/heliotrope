# frozen_string_literal: true

class RecacheInCommonMetadataJob < ApplicationJob
  XML_FILE = Rails.root.join('tmp', 'InCommon-metadata.xml')
  DOWNLOAD_CMD = "curl --silent https://md.incommon.org/InCommon/InCommon-metadata.xml > #{XML_FILE}"
  JSON_FILE = Rails.root.join('tmp', 'InCommon-metadata.json')
  RAILS_CACHE_KEY = 'in_common_metadata'

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

  def self.system_call(command)
    system(command)
  end

  def perform
    return false unless download_xml
    return false unless parse_xml
    return false unless cache_json
    return false unless in_common
    true
  end

  def download_xml
    command = DOWNLOAD_CMD
    rvalue = self.class.system_call(command)
    return true if rvalue
    case rvalue
    when false
      Rails.logger.error("ERROR Command #{command} error code #{self.class.system_call($?)}")
    else
      Rails.logger.error("ERROR Command #{command} not found #{self.class.system_call($?)}")
    end
    false
  end

  def parse_xml
    first = true
    File.open(JSON_FILE, 'w') do |file|
      file << "[\n"
      if File.exist?(XML_FILE)
        Nokogiri::XML::Reader(File.open(XML_FILE)).each do |node|
          if node.name == 'EntityDescriptor' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            file << ",\n" unless first
            file << EntityDescriptor.new(Nokogiri::XML(node.outer_xml).at('EntityDescriptor')).to_json
            first = false
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

        institution = Greensub::Institution.find_by(entity_id: entry["entityID"])
        institution.in_common = true
        institution.save!
      end
    end
    true
  end
end
