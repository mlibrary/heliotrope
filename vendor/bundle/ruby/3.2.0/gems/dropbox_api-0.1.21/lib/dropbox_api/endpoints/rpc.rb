# frozen_string_literal: true
module DropboxApi::Endpoints
  class Rpc < DropboxApi::Endpoints::Base
    def build_connection
      @connection = @builder.build('https://api.dropboxapi.com') do |c|
        c.response :decode_result
      end
    end

    def build_request(params)
      request_headers = {
        'content-type' => 'application/json'
      }

      return request_body(params), request_headers
    end

    def request_body(params)
      # This check is only required for compatibility with old JSON serializers
      if params.nil?
        'null'
      else
        JSON.dump(params)
      end
    end
  end
end
