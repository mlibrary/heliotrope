# frozen_string_literal: true

module FulcrumDashboardHelper
  # Used in views/fulcrum/_sidebar.html.erb
  def active?(partial, this_partial)
    return %|class="nav-item active"|.html_safe if partial == this_partial
    %|class="nav-item"|.html_safe
  end
end
