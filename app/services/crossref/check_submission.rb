# frozen_string_literal: true

module Crossref
  class CheckSubmission
    attr_reader :file_name, :config

    # You can use the doi_batch_id to query the xref submission log
    # unless there was a parsing error. In that case you have to
    # use the file_name. Always using the file_name is recommended.
    # https://support.crossref.org/hc/en-us/articles/217515926-Using-HTTPS-to-retrieve-logs
    def initialize(file_name, config = Crossref::Config)
      @file_name = file_name
      @config = config.load_config
    end

    def fetch
      request = Typhoeus::Request.new(
        @config['check_url'],
        method: :get,
        params: {
          usr: @config['login_id'],
          pwd: @config['login_passwd'],
          file_name: @file_name,
          type: "result"
        }
      )
      resp = request.run
      resp
    end
  end
end
