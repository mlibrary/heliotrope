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
          set_presses_and_institutions if @partial == 'counter'
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

        flash[:notice] = "The #{params[:report_type]} report for #{Press.find(params[:press]).name} will be sent to #{args[:email]}"
        redirect_to hyrax.admin_stats_path(partial: 'institution')
      end

      def counter_report
        args = params.permit!.to_h
        report_type = args.delete(:report_type)
        email = args.delete(:email)
        args.delete(:action)
        args.delete(:controller)

        unless ValidationService.valid_email?(email)
          flash[:alert] = "The email address #{email} is not a valid email address"
          redirect_to hyrax.admin_stats_path(partial: 'counter')
          return
        end

        begin Date.parse(params[:start_date])
        rescue StandardError => _e
          flash[:alert] = "Please enter a valid start date"
          redirect_to hyrax.admin_stats_path(partial: 'counter')
          return
        end

        begin Date.parse(params[:end_date])
        rescue StandardError => _e
          flash[:alert] = "Please enter a valid end date"
          redirect_to hyrax.admin_stats_path(partial: 'counter')
          return
        end

        EmailCounterReportJob.perform_later(email: email, report_type: report_type, args: args)

        flash[:notice] = "The #{report_type.upcase} report for #{Press.find(args[:press]).name} will be sent to #{email}"
        redirect_to hyrax.admin_stats_path(partial: 'counter')
      end

      private

        def only_elevated_users
          return if current_ability.platform_admin? || current_ability.press_admin? || current_ability.press_editor? || current_ability.press_analyst?
          render 'hyrax/base/unauthorized', status: :unauthorized
        end

        def set_presses_and_institutions
          # Only presses the user is affiliated with (are an admin, editor, etc)
          @presses = (current_user&.admin_presses + current_user&.editor_presses + current_user&.analyst_presses).uniq
          # Reports can be "all institutions" at once or each individual institution seperately
          @institutions = Greensub::Institution.order(:name).to_a.unshift(Greensub::Institution.new(name: "All Institutions", identifier: '*'))
        end
    end
  end
end
