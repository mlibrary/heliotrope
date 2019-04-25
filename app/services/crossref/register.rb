# frozen_string_literal: true

module Crossref
  class Register
    attr_reader :xml, :config

    def initialize(xml)
      @xml = xml
      @config = load_config
    end

    def post
      # Tempfile foolishness just to make POST work. I'm tired of fighting with it.
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
      resp = request.run
      tmp.unlink
      resp
    end

    private

      def doi_batch_id
        doc = Nokogiri::XML(@xml)
        doc.at_css('doi_batch_id').content
      end

      def load_config
        filename = Rails.root.join('config', 'crossref.yml')
        yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
        unless yaml
          Rails.logger.error("Unable to fetch any keys from #{filename}.")
          return {}
        end
        yaml.fetch("crossref")
      end
  end
end
