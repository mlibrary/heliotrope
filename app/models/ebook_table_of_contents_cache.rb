# frozen_string_literal: true

class EbookTableOfContentsCache < ApplicationRecord
  validates :noid, presence: true, allow_blank: false, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :toc, presence: true, allow_blank: false
end
