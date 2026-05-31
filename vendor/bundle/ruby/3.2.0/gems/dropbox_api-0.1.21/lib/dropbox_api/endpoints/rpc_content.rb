# frozen_string_literal: true
module DropboxApi::Endpoints
  class RpcContent < DropboxApi::Endpoints::Rpc
    def build_connection
      @connection = @builder.build('https://content.dropboxapi.com') do |c|
        c.response :decode_result
      end
    end
  end
end
