class Press < ActiveRecord::Base
  validates :subdomain, presence: true, uniqueness: true
  has_many :roles, as: :resource, dependent: :delete_all
  has_many :sub_brands
  accepts_nested_attributes_for :roles, allow_destroy: true, reject_if: proc { |attr| attr['user_key'].blank? && attr['id'].blank? }

  def to_param
    subdomain
  end
end
