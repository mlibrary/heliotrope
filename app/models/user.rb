# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  include Hyrax::WithEvents
  # Adds acts_as_messageable for user mailboxes
  include Mailboxer::Models::Messageable

  has_many :roles, dependent: :destroy
  has_many :presses, through: :roles, source: 'resource', source_type: "Press"

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  alias_attribute :user_key, :email

  # Override Hyrda
  # current_user.groups is used in lot of places like
  # blacklight-access-controls, hydra-access-controls, hyrax.
  # This returns an array of "publisher_roles" like:
  # ["northwestern_admin", "northwestern_editor"]
  # These correspond to read_groups or edit_groups
  # in a Monograph or FileSet
  def groups
    if platform_admin?
      Role::ROLES.map do |r|
        Press.all.map { |p| "#{p.subdomain}_#{r}" }
      end.flatten.sort + ['admin']
      # Adding just 'admin' since I *think* we'll need this for hyrax 2 admin dashboard.
      # We're completly overriding whatever RoleMapper or config/role_map.yml would give
      # from hydra-access-controls lib/hydra/user.rb
    else
      press_roles.map do |r|
        Press.all.map { |p| "#{p.subdomain}_#{r.role}" if r.resource_id == p.id }
      end.flatten.compact.sort
    end
  end

  def press_roles
    roles.where(resource_type: 'Press')
  end

  def admin_roles
    press_roles.where(role: 'admin')
  end

  # Presses for which this user is an admin
  def admin_presses
    platform_admin? ? Press.all : presses.where(['roles.role = ?', 'admin'])
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
