# frozen_string_literal: true

module Keycard::Request
  # This class extracts attributes for Cosign-protected applications. It
  # follows the same basic pattern as for general proxied requests; that is,
  # the pid/eid are the same and there are currently no additional
  # attributes extracted.
  class CosignAttributes < Attributes
    def user_pid
      get "HTTP_X_REMOTE_USER"
    end

    def user_eid
      user_pid
    end

    def client_ip
      safe("HTTP_X_FORWARDED_FOR").split(",").first
    end
  end
end
