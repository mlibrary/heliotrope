# frozen_string_literal: true

module Crossref
  class Register
    attr_reader :xml, :config

    def initialize(xml, config = Crossref::Config)
      @xml = xml
      @config = config.load_config
    end

    def post
      tmp = Tempfile.new(doi_batch_id)
      tmp.write(@xml)
      tmp.close
      request = Typhoeus::Request.new(
        @config['deposit_url'],
        method: :post,
        body: { fname: tmp },
        params: {
          login_id: @config['login_id'],
          login_passwd: @config['login_passwd']
        }
      )
      response = request.run
      submission = CrossrefSubmissionLog.new(doi_batch_id: doi_batch_id,
                                             initial_http_status: response.code,
                                             initial_http_message: response.body,
                                             file_name: File.basename(tmp),
                                             submission_xml: @xml)
      submission.status = if response.code == 200
                            "submitted"
                          else
                            "error"
                          end
      submission.save!
      tmp.unlink

      response
    end

    private

      def doi_batch_id
        doc = Nokogiri::XML(@xml)
        doc.at_css('doi_batch_id').content
      end
  end
end
