# frozen_string_literal: true

class User < ApplicationRecord
  include Actorable
  include Filterable

  scope :identifier_like, ->(like) { where("email like ?", "%#{like}%") }
  scope :name_like, ->(like) { where("display_name like ?", "%#{like}%") }
  scope :email_like, ->(like) { where("email like ?", "%#{like}%") }

  validates :email, presence: true, allow_blank: false, uniqueness: true

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

  # Register available devise modules. For the standard modules that Devise provides, this method is
  # called from lib/devise/modules.rb. Third-party modules need to be added explicitly using this method.
  #
  # Note that adding a module using this method does not cause it to be used in the authentication
  # process. That requires that the module be listed in the arguments passed to the 'devise' method
  # in the model class definition.
  #
  # == Options:
  #
  #   +model+      - String representing the load path to a custom *model* for this module (to autoload.)
  #   +controller+ - Symbol representing the name of an existing or custom *controller* for this module.
  #   +route+      - Symbol representing the named *route* helper for this module.
  #   +strategy+   - Symbol representing if this module got a custom *strategy*.
  #   +insert_at+  - Integer representing the order in which this module's model will be included
  #
  # All values, except :model, accept also a boolean and will have the same name as the given module
  # name.
  #
  # == Examples:
  #
  #   Devise.add_module(:party_module)
  #   Devise.add_module(:party_module, strategy: true, controller: :sessions)
  #   Devise.add_module(:party_module, model: 'party_module/model')
  #   Devise.add_module(:party_module, insert_at: 0)
  #
  # Authenticate users with Keycard. The Keycard.config.access setting
  # will determine exactly how that happens (direct, reverse proxy, Shibboleth).
  Devise.add_module(:keycard_authenticatable,
                    strategy: true,
                    controller: :sessions,
                    model: 'devise/models/keycard_authenticatable')

  # Devise modules
  # :database_authenticatable, :registerable, :recoverable, :rememberable,
  # :trackable, :validatable, :confirmable, :lockable, :timeoutable and :omniauthable

  devise :keycard_authenticatable

  alias_attribute :user_key, :email

  # Guest factory
  def self.guest(user_key:)
    Guest.new(user_key: user_key)
  end

  # Override Hydra
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

  def role?
    roles.any?
  end

  def press_roles
    roles.where(resource_type: 'Press')
  end

  def admin_roles
    press_roles.where(role: 'admin')
  end

  def editor_roles
    press_roles.where(role: 'editor')
  end

  def analyst_roles
    press_roles.where(role: 'analyst')
  end

  # Presses for which this user is an editor
  def editor_presses
    platform_admin? ? Press.order(:name) : presses.where(roles: { role: 'editor' }).order(:name)
  end

  # Presses for which this user is an admin
  def admin_presses
    platform_admin? ? Press.order(:name) : presses.where(roles: { role: 'admin' }).order(:name)
  end

  def analyst_presses
    platform_admin? ? Press.order(:name) : presses.where(roles: { role: 'analyst' }).order(:name)
  end

  def platform_admin?
    roles.where(role: 'admin', resource: nil).any?
  end

  def developer?
    Incognito.developer?(self)
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    user_key
  end

  def token
    JsonWebToken.encode(email: email, pin: encrypted_password)
  end

  def tokenize!
    self.encrypted_password = SecureRandom.urlsafe_base64(12)
    save!
  end

  def identifier
    user_key
  end

  def name
    display_name || identifier
  end

  def grants?
    Authority.agent_grants?(self)
  end

  def agent_type
    :User
  end

  def agent_id
    id
  end
end
