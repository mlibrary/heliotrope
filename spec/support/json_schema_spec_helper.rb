# frozen_string_literal: true

module JsonSchemaSpecHelper
  # resolve external references
  # 'net/http'/proc/lambda/respond_to?(:call)
  # 'net/http': proc { |uri| JSON.parse(Net::HTTP.get(uri)) }
  # default: proc { |uri| raise UnknownRef, uri.to_s }
  def reference_resolver(uri)
    JSON.parse(Net::HTTP.get(uri))
  end

  def meta_schemer
    @meta_schemer ||= JSONSchemer.schema(Net::HTTP.get(URI('https://json-schema.org/draft-07/schema')), ref_resolver: proc { |uri| reference_resolver(uri) })
  end

  def opds_feed_schemer
    @opds_feed_schemer ||= JSONSchemer.schema(Net::HTTP.get(URI('https://drafts.opds.io/schema/feed.schema.json')), ref_resolver: proc { |uri| reference_resolver(uri) })
  end

  def opds_publication_schemer
    @opds_publication_schemer ||= JSONSchemer.schema(Net::HTTP.get(URI('https://drafts.opds.io/schema/publication.schema.json')), ref_resolver: proc { |uri| reference_resolver(uri) })
  end

  def schemer_validate?(schemer, json_obj)
    rvalue = true
    schemer.validate(json_obj).each do |verr|
      rvalue = false
      error = case verr["type"]
              when "required"
                "Path '#{verr["data_pointer"]}' is missing keys: #{verr["details"]["missing_keys"].join ', '}"
              when "format"
                "Path '#{verr["data_pointer"]}' is not in required format (#{verr["schema"]["format"]})"
              when "minLength"
                "Path '#{verr["data_pointer"]}' is not long enough (min #{verr["schema"]["minLength"]})"
              when "contains"
                # "Path '#{verr["data_pointer"]}' #{verr["schema"]["contains"]["description"] || verr["schema"]["contains"]["properties"]}"
                "Path '#{verr["data_pointer"]}' #{verr["schema"]["contains"]}"
              when "minItems"
                "Path '#{verr["data_pointer"]}' not enough items (min #{verr["schema"]["minItems"]})"
              else
                "There is a problem with path '#{verr["data_pointer"]}'. Please check your input."
              end
      puts "- #{error}"
    end
    rvalue
  end
end
