# frozen_string_literal: true

module Hyrax
  module Admin
    class StatsController < ApplicationController
      include Hyrax::Admin::StatsBehavior
      before_action :authenticate_user!
      before_action :only_elevated_users

      def show
        @partial = params[:partial]
        render 'hyrax/base/unauthorized', status: :unauthorized unless ['analytics', 'counter', 'altmetric', 'dimensions', 'institution', 'licenses'].include?(@partial)

        if @partial == 'counter'
          set_presses
          set_institutions
        end

        if @partial == 'licenses'
          set_presses
          if params[:product_ids].present?
            @show_report = true if params[:show_report].present?
            products_for_licenses_report
          else
            products_for_dropdown
          end
        end

        if params[:format] == "csv"
          send_data csv_products_for_licenses, type: "text/csv", filename: "Fulcrum_Product_Licenses_Report.csv"
        else
          render
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

        # Force defaults for Master reports, HELIO-4282 and HELIO-4283
        if report_type == "pr" || report_type == "tr" || report_type == "ir"
          args[:attributes_to_show] = ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"]
          args[:data_types] = ["Book", "Multimedia", "Book_Segment"] if report_type == "ir"
          args[:include_parent_details] = "true" if report_type == "ir"
          args[:include_component_details] = "true" if report_type == "ir" # needed to see titles of downloaded chapters
          args[:exclude_monthly_details] = "false"
          args[:include_monthly_details] = "true"
        end

        EmailCounterReportJob.perform_later(email: email, report_type: report_type, args: args)

        flash[:notice] = "The #{report_type.upcase} report for #{Press.find(args[:press]).name} will be sent to #{email}"
        redirect_to hyrax.admin_stats_path(partial: 'counter')
      end

      # Show products that have licenses (so no leverpress here) that you have permisions for (press admin, editor or analyst)
      # It's sort of dumb since the form is GET and in theory one could just add product ids to the url to see everything
      # but we're not concerned about that. It's mostly keeping the list relevent to the user, not keeping anyone from seeing
      # anything they're "not supposed to".
      def products_for_dropdown
        product_ids = []
        ActiveFedora::SolrService.query("{!terms f=press_sim}#{@presses.map(&:subdomain).join(',')}", fl: ['products_lsim'], rows: 100_000).each do |doc|
          doc["products_lsim"].each do |pid|
            next if pid == 0
            next if pid == -1
            product_ids << pid unless product_ids.any?(pid)
          end
        end

        @products = []
        Greensub::Product.where(id: product_ids).order(:name).each do |product|
          next if product.licenses.empty?
          @products << product
        end
      end

      def products_for_licenses_report
        @products = Greensub::Product.where(id: params[:product_ids]).order(:name)
      end

      # This is not performant but also seldom used
      # This is also true for views/hyrax/admin/stats/_licenses.html.erb which is basically the same code ¯\_(ツ)_/¯
      def csv_products_for_licenses
        CSV.generate(headers: true) do |csv|
          csv << ["Product Identifier", "Licensee", "dlpsid", "License Type", "Affiliations"]
          @products.each do |product|
            product.institutions_ordered_by_name.each do |inst|
              license = product.licenses.where(licensee_id: inst.id).first
              csv << [
                product.identifier,
                inst.name,
                inst.identifier,
                license.label,
                license.affiliations.map(&:affiliation).join("|")
              ]
            end

            product.individuals_ordered_by_email.each do |indv|
              license = product.licenses.where(licensee_id: indv.id).first
              csv << [
                product.identifier,
                indv.email,
                "",
                license.label,
                license.affiliations.map(&:affiliation).join("|")
              ]
            end
          end
        end
      end

      private

        def only_elevated_users
          return if current_ability.platform_admin? || current_ability.press_admin? || current_ability.press_editor? || current_ability.press_analyst?
          render 'hyrax/base/unauthorized', status: :unauthorized
        end

        def set_presses
          # Only presses the user is affiliated with (are an admin, editor, etc)
          @presses = (current_user&.admin_presses + current_user&.editor_presses + current_user&.analyst_presses).uniq
        end

        def set_institutions
          # Reports can be "all institutions" at once or each individual institution seperately
          @institutions = Greensub::Institution.order(:name).to_a.unshift(Greensub::Institution.new(name: "All Institutions", identifier: '*'))
        end
    end
  end
end
