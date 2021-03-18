# frozen_string_literal: true

module Greensub
  class LicenseCredential < Checkpoint::Credential
    TYPE = 'License'

    def type
      TYPE
    end
  end
end
