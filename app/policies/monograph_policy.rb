# frozen_string_literal: true

class MonographPolicy < ResourcePolicy
  def initialize(actor, target)
    super(actor, target)
  end

  def epub_policy
    EPubPolicy.new(actor, target.epub_featured_representative)
  end
end
