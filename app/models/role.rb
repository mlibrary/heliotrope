# frozen_string_literal: true

class Role < ApplicationRecord
  ROLES = %w[admin editor analyst].freeze
  # A platform_admin has a role of "admin" with a resource of "nil" so
  # we need belongs_to: resource to be optional. In rails 5 this defaults to false.
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :user
  validates :role, inclusion: { in: ROLES }
  validates :user_key, presence: true
  validate :user_must_exist, if: -> { user_key.present? }
  validate :user_must_be_unique, if: :user

  def user_key
    if user
      @user_key = user.user_key
    else
      @user_key
    end
  end

  # setting user key causes the user to get set
  def user_key=(key)
    @user_key = key
    self.user ||= ::User.find_by(user_key: key)
    user&.user_key = key
  end

  protected

    def user_must_exist
      errors.add(:user_key, 'User must sign up first.') if user.blank?
    end

    # This is just like
    #    validates :user, uniqueness: { scope: :press}
    # but it puts the error message on the user_key instead of user so that the form will render correctly
    def user_must_be_unique
      errors.add(:user_key, 'already a member of this press') if Role.where(resource: resource, user_id: user.id).where.not(id: id).any?
    end
end
