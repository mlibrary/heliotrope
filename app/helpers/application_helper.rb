# frozen_string_literal: true

module ApplicationHelper
  delegate :current_actor, :current_institution, :current_institutions?, :current_institutions, to: :controller

  def controller_body_class
    case controller_name
    when 'catalog' then 'heliotrope-catalog'
    when 'admin_catalog' then 'heliotrope-admin-catalog'
    else nil
    end
  end
end
