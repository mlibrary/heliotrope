# frozen_string_literal: true

class EbookReaderOperation < EbookOperation
  include Skylight::Helpers

  instrument_method
  def allowed?
    return true if can? :read

    return false unless accessible_online?

    unrestricted? || licensed_for?(:reader)
  end
end
