# frozen_string_literal: true
module DropboxApi::Endpoints
  class ContentDownload < DropboxApi::Endpoints::Base
    def build_connection
      @connection = @builder.build('https://content.dropboxapi.com') do |c|
        c.response :decode_result
      end
    end

    def build_request(params)
      body = nil
      headers = {
        'Dropbox-API-Arg' => JSON.dump(params),
        'Content-Type' => ''
      }

      return body, headers
    end

    def perform_request(params)
      response = get_response(params)
      api_result = process_response response

      # We just yield the whole response to the block, it'd be nice in the
      # future to support an interface that streams the response in chunks.
      yield response.body if block_given?

      api_result
    end
  end
end
