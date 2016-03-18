class Press < ActiveRecord::Base
  validates :subdomain, presence: true, uniqueness: true

  def to_param
    subdomain
  end
end
