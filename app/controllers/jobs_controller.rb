# frozen_string_literal: true

class JobsController < ApplicationController
  # For a user with the right authorization, the controllers in
  # the mounted ResqueWeb engine should handle the web request.
  # If the web request falls through to this controller, then
  # the user shouldn't be allowed access to ResqueWeb.
  def forbid
    raise ::CanCan::AccessDenied unless current_user
    render_404
  end

  def render_404
    render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
  end
end
