# frozen_string_literal: true

class Press < ApplicationRecord
  mount_uploader :logo_path, LogoPathUploader
  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true
  validates :description, presence: true, uniqueness: true
  # don't want to add a gem for this right now, this will at least prevent relative links
  validates :press_url, presence: true, uniqueness: true, format: URI.regexp(%w[http https])

  has_many :roles, as: :resource, dependent: :delete_all
  has_many :sub_brands
  accepts_nested_attributes_for :roles, allow_destroy: true, reject_if: proc { |attr| attr['user_key'].blank? && attr['id'].blank? }

  # A Press can have a parent press and can have children presses
  belongs_to :parent, class_name: 'Press', optional: true
  has_many :children, class_name: 'Press', foreign_key: 'parent_id'
  # Get only presses that are "root" parents
  scope :parent_presses, -> { where(parent_id: nil) }

  def to_param
    subdomain
  end
end
