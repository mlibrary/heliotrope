class Role < ActiveRecord::Base
  ROLES = %w(admin).freeze
  belongs_to :resource, polymorphic: true
  belongs_to :user
  validates :role, inclusion: { in: ROLES }
end
