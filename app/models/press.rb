# frozen_string_literal: true

class Press < ApplicationRecord
  mount_uploader :logo_path, LogoPathUploader
  validates :name, presence: true, uniqueness: { case_sensitive: true } # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :subdomain, presence: true, uniqueness: { case_sensitive: true }, # rubocop:disable Rails/UniqueValidationWithoutIndex
            length: { minimum: 2, maximum: 32 },
            format: { with: /\A[-0-9a-z]+\z/, message: :format }
  validate :subdomain_hyphens
  validates :description, presence: true, uniqueness: { case_sensitive: true } # rubocop:disable Rails/UniqueValidationWithoutIndex
  # don't want to add a gem for this right now, this will at least prevent relative links
  validates :press_url, presence: true, uniqueness: { case_sensitive: true }, format: URI.regexp(%w[http https]) # rubocop:disable Rails/UniqueValidationWithoutIndex

  has_many :roles, as: :resource, dependent: :delete_all
  accepts_nested_attributes_for :roles, allow_destroy: true, reject_if: proc { |attr| attr['user_key'].blank? && attr['id'].blank? }

  # A Press can have a parent press and can have children presses
  belongs_to :parent, class_name: 'Press', optional: true, inverse_of: :children
  has_many :children, class_name: 'Press', foreign_key: 'parent_id', inverse_of: :parent, dependent: :nullify
  # Get only presses that are "root" parents
  scope :parent_presses, -> { where(parent_id: nil) }

  def allow_share_links?
    return true if share_links == true
    false
  end

  def create_dois?
    return true if doi_creation == true
    false
  end

  # HELIO-3275
  # "aboutware" means:
  #   * don't show the jumbotron on the press page
  #   * changes breadcrumbs to include the "aboutware" website
  # "aboutware" IS NOT neccessarily
  #   * show the special complex navigation_block
  # In other words, you can have a navigation_block and NOT have "aboutware"
  def aboutware?
    return true if aboutware == true
    false
  end

  def to_param
    subdomain
  end

  def agent_type
    :Press
  end

  def agent_id
    id
  end

  def self.null_press
    NullPress.new
  end

  def subdomain_hyphens
    return if subdomain.blank?
    errors.add(:subdomain, :hyphens) if subdomain.start_with?('-') || subdomain.end_with?('-') || subdomain.include?('--')
  end
end
