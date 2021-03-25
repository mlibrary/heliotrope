# frozen_string_literal: true

class EbookReaderOperation < EbookOperation
  def allowed?
    licensed_for?(:reader)
  end
end
