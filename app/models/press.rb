# frozen_string_literal: true

class Press < ActiveRecord::Base
  mount_uploader :logo_path, LogoPathUploader
  validates :logo_path, presence: true

  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true
  validates :description, presence: true, uniqueness: true
  # don't want to add a gem for this right now, this will at least prevent relative links
  validates :press_url, presence: true, uniqueness: true, format: URI.regexp(%w[http https])
  validates :google_analytics, presence: true, uniqueness: true

  has_many :roles, as: :resource, dependent: :delete_all
  has_many :sub_brands
  accepts_nested_attributes_for :roles, allow_destroy: true, reject_if: proc { |attr| attr['user_key'].blank? && attr['id'].blank? }

  def to_param
    subdomain
  end
end
