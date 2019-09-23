# frozen_string_literal: true

class HandleService
  DOI_ORG_PREFIX = 'https://doi.org/'
  HANDLE_NET_PREFIX = 'https://hdl.handle.net/'
  HANDLE_NET_API_HANDLES = (HANDLE_NET_PREFIX + 'api/handles/').freeze
  FULCRUM_PREFIX = '2027/fulcrum.'

  def self.noid(handle_path_or_url)
    match = /^(.*)(#{Regexp.escape(FULCRUM_PREFIX)})(.*)$/i.match(handle_path_or_url || "")
    return nil if match.nil?
    noid = /^[[:alnum:]]{9}$/i.match(match[3])
    return match[3] unless noid.nil?
    noid = /^([[:alnum:]]{9})\?(.*)$/i.match(match[3])
    return nil if noid.nil?
    noid[1]
  end

  def self.path(noid)
    FULCRUM_PREFIX + noid.to_s
  end

  def self.url(noid)
    HANDLE_NET_PREFIX + path(noid)
  end

  def self.value(noid) # rubocop:disable Metrics/CyclomaticComplexity
    # Proxy Server REST API
    #
    # The handle proxy REST API allows programmatic access to handle resolution using HTTP.
    #
    #     Example Request/Response
    #
    # A REST API request can be made by performing a standard HTTP GET of
    #
    # /api/handles/<handle>
    #
    #     The API returns JSON.
    #
    #     For example, https://hdl.handle.net/api/handles/4263537/4000
    #
    # Response Codes
    #
    # 1 : Success. (HTTP 200 OK)
    # 2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)
    # 100 : Handle Not Found. (HTTP 404 Not Found)
    # 200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)
    response = Faraday.get(HANDLE_NET_API_HANDLES + path(noid))
    body = JSON.parse(response.body)
    url = nil
    if response.status == 200 && body['responseCode'] == 1
      body['values'].each do |value|
        url ||= value['data']['value'] if value['type'] == 'URL'
      end
      url ||= "1 : Success. (HTTP 200 OK)"
    else
      url = case body['responseCode']
            when 2
              "2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)"
            when 100
              "100 : Handle Not Found. (HTTP 404 Not Found)"
            when 200
              "200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)"
            end
    end
    url
  end
end
