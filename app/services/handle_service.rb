# frozen_string_literal: true

class HandleService
  def self.noid(handle_path_or_url)
    match = /^(.*)(2027\/fulcrum\.)(.*)$/i.match(handle_path_or_url || "")
    return nil if match.nil?
    noid = /^[[:alnum:]]{9}$/i.match(match[3])
    return match[3] unless noid.nil?
    noid = /^([[:alnum:]]{9})\?(.*)$/i.match(match[3])
    return nil if noid.nil?
    noid[1]
  end

  def self.path(noid)
    "2027/fulcrum.#{noid}"
  end

  def self.url(noid)
    "http://hdl.handle.net/#{path(noid)}"
  end

  def self.value(noid)
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
    #     For example, http://hdl.handle.net/api/handles/4263537/4000
    #
    # Response Codes
    #
    # 1 : Success. (HTTP 200 OK)
    # 2 : Error. Something unexpected went wrong during handle resolution. (HTTP 500 Internal Server Error)
    # 100 : Handle Not Found. (HTTP 404 Not Found)
    # 200 : Values Not Found. The handle exists but has no values (or no values according to the types and indices specified). (HTTP 200 OK)
    response = Faraday.get("http://hdl.handle.net/api/handles/#{path(noid)}")
    url = nil
    if response.code == 200 && response['responseCode'] == 1
      response['values'].each do |value|
        url ||= value['data']['value'] if value['type'] == 'URL'
      end
    end
    url
  end
end
