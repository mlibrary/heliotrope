class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include CurationConcerns::User
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  has_many :roles, dependent: :destroy
  has_many :presses, through: :roles, source: 'resource', source_type: "Press"

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  alias_attribute :user_key, :email

  def press_roles
    roles.where(resource_type: 'Press')
  end

  def admin_roles
    press_roles.where(role: 'admin')
  end

  def platform_admin?
    roles.where(role: 'admin', resource: nil).any?
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    user_key
  end
end
