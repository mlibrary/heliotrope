# frozen_string_literal: true

module Greensub
  class LicenseGrant < Checkpoint::DB::Grant
    def save!
      save
    end
  end
end
