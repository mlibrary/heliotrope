# frozen_string_literal: true

class EntityPolicy < ResourcePolicy
  def initialize(actor, target)
    super(actor, target)
  end

  def download? # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    value = Sighrax.downloadable?(target)
    debug_log("downloadable? #{value}")
    return false unless value

    value = Sighrax.platform_admin?(actor)
    debug_log("platform_admin? #{value}")
    return true if value

    value = Sighrax.hyrax_can?(actor, :edit, target)
    debug_log("hyrax_can(:edit)? #{value}")
    return true if value

    value = Sighrax.tombstone?(target)
    debug_log("tombstone? #{value}")
    return false if value

    value = Sighrax.allow_download?(target)
    debug_log("allow_download? #{value}")
    return false unless value

    value = Sighrax.published?(target)
    debug_log("published? #{value}")
    return false unless value

    value = target.instance_of?(Sighrax::Asset)
    debug_log("instance_of?(Sighrax::Asset) #{value}")
    return true if value

    value = Sighrax.open_access?(target.parent)
    debug_log("open_access? #{value}")
    return true if value

    value = Sighrax.restricted?(target.parent)
    debug_log("restricted? #{value}")
    return true unless value

    value = Sighrax.access?(actor, target.parent)
    debug_log("access? #{value}")
    value
  end
end
