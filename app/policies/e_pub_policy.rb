# frozen_string_literal: true

class EPubPolicy < ApplicationPolicy
  def initialize(actor, target, share = false)
    super(actor, target)
    @share = share
  end

  def show?
    return true if ebook.published? && !ebook.tombstone? && share

    EbookReaderOperation.new(actor, ebook).allowed?
  end

  protected

    alias_attribute :ebook, :target
    attr_reader :share
end
