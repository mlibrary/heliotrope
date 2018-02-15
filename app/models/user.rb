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

  before_validation :generate_password, on: :create

  def generate_password
    self.password = SecureRandom.urlsafe_base64(12)
    self.password_confirmation = password
  end

  # Use the http header as auth.  This app will be behind a reverse proxy
  #   that will take care of the authentication.
  Devise.add_module(:http_header_authenticatable,
                    strategy: true,
                    controller: :sessions,
                    model: 'devise/models/http_header_authenticatable')

  # Add our custom module to devise.
  devise :http_header_authenticatable

  def populate_attributes
    # TODO: Override this for HttpHeaderAuthenticatable
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # blacklight magic (may not be needed)
  # if Blacklight::Utils.needs_attr_accessible?
  #   attr_accessible :email, :password, :password_confirmation
  # end

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
