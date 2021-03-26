# frozen_string_literal: true

class EPubPolicy < ResourcePolicy
  def initialize(actor, target, share = false)
    @ebook = target
    target = target.parent
    super(actor, target)
    @share = share
  end

  def show? # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    debug_log("show? #{actor.agent_type}:#{actor.agent_id}, #{target.resource_type}:#{target.resource_id}, share is #{share}")

    value = actor.platform_admin? && Incognito.allow_platform_admin?(actor)
    debug_log("platform_admin? #{value}")
    return true if value

    value = Sighrax.published?(target)
    debug_log("published? #{value}")
    if value
      value = Sighrax.open_access?(target)
      debug_log("open_access? #{value}")
      return true if value

      value = Sighrax.restricted?(target)
      debug_log("restricted? #{value}")
      if value
        value = Sighrax.ability_can?(actor, :edit, target) && Incognito.allow_ability_can?(actor)
        debug_log("ability_can(:edit)? #{value}")
        return true if value

        debug_log("share #{share}")
        return true if share

        EbookReaderOperation.new(actor, ebook).allowed?
      else
        true
      end
    else
      value = Sighrax.ability_can?(actor, :edit, target) && Incognito.allow_ability_can?(actor)
      debug_log("ability_can(:edit)? #{value}")
      return true if value

      value = Sighrax.ability_can?(actor, :read, target) && Incognito.allow_ability_can?(actor)
      debug_log("ability_can(:read)? #{value}")
      value
    end
  end

  protected

    attr_reader :ebook
    attr_reader :share
end
