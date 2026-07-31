# frozen_string_literal: true

class FeaturedRepresentative < ApplicationRecord
  KINDS = %w[aboutware audiobook database epub mobi pdf_ebook peer_review related reviews webgl].freeze

  validates :work_id, presence: true
  validates :file_set_id, presence: true, uniqueness: { case_sensitive: true }
  validates :kind, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: :work_id,
                                 message: "Work can only have one of each kind",
                                 case_sensitive: true }
  def self.kinds
    KINDS
  end
end
