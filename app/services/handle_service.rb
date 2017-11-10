# frozen_string_literal: true

class HandleService
  def self.handle?(object)
    !handle(object).nil?
  end

  def self.handle(object)
    return nil if object.nil?
    hdl = object.id if object.respond_to?(:id)
    hdl = object.hdl if object.respond_to?(:hdl) && object.hdl.present?
    return nil if hdl.nil?
    "2027/fulcrum.#{hdl}"
  end

  def self.url(object)
    handle = handle(object)
    return nil if handle.nil?
    "http://hdl.handle.net/#{handle}"
  end

  def self.object(handle)
    return nil unless handle.is_a? String
    match = /(.*)(2027\/fulcrum\.)(.*)$/.match(handle)
    return nil if match.nil?
    actual_noid = if Rails.env.test? || Rails.application.routes.url_helpers.root_url.include?('fulcrum')
                    # only check handle.net when running in 'proper' production
                    noid(match[3])
                  else
                    match[3]
                  end
    ActiveFedora::Base.find(actual_noid)
  end

  private_class_method def self.noid(hdl)
    match = /(.*)(concern\/file_sets\/)(.*)$/.match(value(hdl))
    return hdl if match.nil?
    match[3]
  end

  private_class_method def self.value(hdl)
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
    response = HTTParty.get("http://hdl.handle.net/api/handles/2027/fulcrum.#{hdl}")
    url = nil
    if response.code == 200 && response['responseCode'] == 1
      response['values'].each do |value|
        url ||= value['data']['value'] if value['type'] == 'URL'
      end
    end
    url ||= ""
  end
end
