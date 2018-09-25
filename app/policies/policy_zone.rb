# frozen_string_literal: true

class PolicyZone
  def initialize(zone = Checkpoint::DB::Permit.default_zone)
    @zone = zone
  end

  def entity
    @zone
  end
end
