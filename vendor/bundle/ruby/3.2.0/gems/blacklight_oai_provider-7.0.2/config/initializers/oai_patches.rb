# Fix the OAI gem resource identifier format
# See: https://github.com/code4lib/ruby-oai/issues/38

Rails.application.config.to_prepare do
  OAI::Provider::Response::RecordResponse.class_eval do
    private

    def identifier_for(record)
      "#{provider.prefix}:#{record.id}"
    end
  end

  OAI::Provider::Response::Base.class_eval do
    private

    def extract_identifier(id)
      id.sub("#{provider.prefix}:", '')
    end
  end
end
