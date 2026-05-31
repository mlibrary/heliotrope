module BlacklightOaiProvider
  class ResumptionToken < ::OAI::Provider::ResumptionToken
    # parses a token string and returns a ResumptionToken
    def self.parse(token_string)
      options = {}
      total = nil
      matches = /(.+):(\d+)$/.match(token_string)
      options[:last] = matches.captures[1].to_i

      parts = matches.captures[0].split('.')
      options[:metadata_prefix] = parts.shift
      parts.each do |part|
        case part
        when /^s/
          options[:set] = part.sub(/^s\(/, '').sub(/\)$/, '')
        when /^f/
          options[:from] = parse_date(part.sub(/^f\(/, '').sub(/\)$/, ''))
        when /^u/
          options[:until] = parse_date(part.sub(/^u\(/, '').sub(/\)$/, ''))
        when /^t/
          total = part.sub(/^t\(/, '').sub(/\)$/, '').to_i
        end
      end
      new(options, nil, total)
    rescue StandardError
      raise OAI::ResumptionTokenException
    end

    # Force date to be in UTC. If date does not have a timezone UTC is assumed.
    # If date is a different timezone it is converted to UTC.
    def self.parse_date(str)
      ActiveSupport::TimeZone.new('UTC').parse(str)
    end

    def encode_conditions
      encoded_token = @prefix.to_s.dup
      encoded_token << ".s(#{set})" if set
      encoded_token << ".f(#{from.utc.xmlschema})" if from
      encoded_token << ".u(#{self.until.utc.xmlschema})" if self.until
      encoded_token << ".t(#{total})" if total
      encoded_token << ":#{last}"
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      token = total && (last > total) ? '' : encode_conditions
      xml.resumptionToken(token, hash_of_attributes)
      xml.target!
    end
  end
end
