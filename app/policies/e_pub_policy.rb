# frozen_string_literal: true

class EPubPolicy < ApplicationPolicy
  def initialize(current_user, e_pub = nil)
    super(current_user, EPub, e_pub)
  end

  def show?
    Component.find_by(handle: HandleService.path(e_pub&.id)).blank?
  end
end
