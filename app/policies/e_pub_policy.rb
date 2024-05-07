# frozen_string_literal: true

class EPubPolicy < ApplicationPolicy
  include Skylight::Helpers

  def initialize(actor, target, share = false)
    super(actor, target)
    @share = share
  end

  instrument_method
  def show?
    return true if !ebook.tombstone? && share

    EbookReaderOperation.new(actor, ebook).allowed?
  end

  protected

    alias_attribute :ebook, :target
    attr_reader :share
end
