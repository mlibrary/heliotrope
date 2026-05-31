# frozen_string_literal: true

module Keycard::Request
  # This class should be used to extract attributes when the application will
  # serve HTTP requests directly or through a proxy that passes trusted
  # values into the application environment to be accessed as usual.
  class DirectAttributes < Attributes
    def user_pid
      get "REMOTE_USER"
    end

    def user_eid
      user_pid
    end

    def client_ip
      safe("REMOTE_ADDR").split(",").first
    end
  end
end
