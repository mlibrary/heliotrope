# frozen_string_literal: true

module Hyrax
  module Admin
    class StatsController < ApplicationController
      include Hyrax::Admin::StatsBehavior
      before_action :authenticate_user!

      def show
        @partial = params[:partial]
        if ['analytics', 'counter', 'altmetric', 'dimensions'].include?(@partial)
          render
        else
          render 'hyrax/base/unauthorized', status: :unauthorized
        end
      end
    end
  end
end
