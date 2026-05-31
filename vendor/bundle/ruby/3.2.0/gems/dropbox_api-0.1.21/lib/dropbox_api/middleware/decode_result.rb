# frozen_string_literal: true
module DropboxApi::MiddleWare
  class DecodeResult < Faraday::Middleware
    def call(rq_env)
      @app.call(rq_env).on_complete do |rs_env|
        if !rs_env[:response_headers]['Dropbox-Api-Result'].nil?
          rs_env[:api_result] = decode rs_env[:response_headers]['Dropbox-Api-Result']
        elsif rs_env[:response_headers]['content-type'] == 'application/json'
          rs_env[:api_result] = decode rs_env[:body]
        end
      end
    end

    def decode(json)
      # Dropbox may send a response with the string 'null' in its body, this
      # would be a void result. `add_folder_member` is an example of an
      # endpoint without return values.
      if json == 'null'
        {}
      else
        JSON.parse json
      end
    end
  end

  Faraday::Response.register_middleware decode_result: DecodeResult
end
