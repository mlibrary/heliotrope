# frozen_string_literal: true

module Hyrax
  module Admin
    class StatsController < ApplicationController
      include Hyrax::Admin::StatsBehavior
      before_action :authenticate_user!
      before_action :only_elevated_users

      def show
        @partial = params[:partial]
        if ['analytics', 'counter', 'altmetric', 'dimensions', 'institution'].include?(@partial)
          render
        else
          render 'hyrax/base/unauthorized', status: :unauthorized
        end
      end

      def institution_report
        args = {}
        args[:email] = params[:email].presence || current_user.email

        unless ValidationService.valid_email?(args[:email])
          flash[:alert] = "The email address #{args[:email]} is not a valid email address"
          redirect_to hyrax.admin_stats_path(partial: 'institution')
          return
        end

        args[:press] = params[:press]
        args[:start_date] = params[:start_date]
        args[:end_date] = params[:end_date]
        args[:report_type] = params[:report_type]

        InstitutionReportJob.perform_later(args: args)

        flash[:notice] = "The #{params[:report_type]} report for #{Press.find(params[:press]).name} will be sent to #{current_user.email}"
        redirect_to hyrax.admin_stats_path(partial: 'institution')
      end

      private

        def only_elevated_users
          return if current_ability.platform_admin? || current_ability.press_admin? || current_ability.press_editor?
          render 'hyrax/base/unauthorized', status: :unauthorized
        end
    end
  end
end
