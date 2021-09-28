# frozen_string_literal: true

module ApplicationHelper
  delegate :current_actor, :current_institution, :current_institutions?, :current_institutions, to: :controller
end
