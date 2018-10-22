# frozen_string_literal: true

class ProductNoid < ApplicationRecord
  include Filterable

  scope :product_like, ->(like) { where("product like ?", "%#{like}%") }
  scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }

  validates :product, presence: true, allow_blank: false
  validates :noid, presence: true, allow_blank: false
  validates :product, uniqueness: { scope: :noid }

  def product_id
    Product.find_by(identifier: product)&.id
  end

  def monograph?
    model = ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
    return false if model.blank?
    /Monograph/i.match?(model["has_model_ssim"]&.first)
  end

  def file_set?
    model = ActiveFedora::SolrService.query("{!terms f=id}#{noid}", rows: 1).first
    return false if model.blank?
    /FileSet/i.match?(model["has_model_ssim"]&.first)
  end
end
