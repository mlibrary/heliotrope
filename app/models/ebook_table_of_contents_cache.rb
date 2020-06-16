# frozen_string_literal: true

class EbookTableOfContentsCache < ApplicationRecord
  validates :noid, presence: true, allow_blank: false, uniqueness: true
  validates :toc, presence: true, allow_blank: false
end
