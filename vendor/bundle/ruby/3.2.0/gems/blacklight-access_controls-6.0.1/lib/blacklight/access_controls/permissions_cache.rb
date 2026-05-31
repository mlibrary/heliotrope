# frozen_string_literal: true

class Blacklight::AccessControls::PermissionsCache
  def initialize
    clear
  end

  def get(pid)
    @cache[pid]
  end

  def put(pid, doc)
    @cache[pid] = doc
  end

  def clear
    @cache = {}
  end
end
