# frozen_string_literal: true

class FeaturedRepresentative < ApplicationRecord
  KINDS = %w[epub webgl database aboutware pdf_ebook mobi].freeze

  validates :monograph_id, presence: true
  validates :file_set_id, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: %i[monograph_id file_set_id],
                                 message: "Only 1 type of Kind can be used for each Monograph's FileSet" }

  def self.kinds
    KINDS
  end
end
