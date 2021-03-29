# frozen_string_literal: true

class MonographPolicy < ApplicationPolicy
  def initialize(actor, target)
    super(actor, target)
  end

  def epub_policy
    EPubPolicy.new(actor, target.epub_featured_representative)
  end

  def pdf_ebook_policy
    EPubPolicy.new(actor, target.pdf_ebook_featured_representative)
  end
end
