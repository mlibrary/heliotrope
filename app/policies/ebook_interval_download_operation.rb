# frozen_string_literal: true

class EbookIntervalDownloadOperation < EbookOperation
  def allowed?
    return false unless ebook.publisher.interval?

    # Interval download is NOT restricted by ebook.allow_download?
    # This is counterintuitive but if you think of the restriction
    # as pertaining to the entire ebook it is a bit easier to swallow
    # since an interval is not the entire ebook (until it is a.k.a.
    # an interval that spans the entire work). Anyway, if you have
    # online access then you may download intervals if the publisher
    # allows interval downloads.
    #
    # This all stems from the derivative nature of the current implementation
    # of intervals. If intervals were to become first class citizens they
    # would have their own interval.allow_download? or perhaps not. Which
    # only opens a can of worms since this is an ebook policy.  Anyway,
    # until things change you're just going to have to deal with it.
    #
    return false unless accessible_online?

    unrestricted? || licensed_for?(:download)
  end
end
