# frozen_string_literal: true

module API
  # Namespace for the public facing SUSHI API REST endpoints
  module Sushi
    module V5
      # Service Controller
      class ServiceController < API::ApplicationController
        skip_before_action :authorize_request, only: %i[sushi]

        # This resource returns information about the service supported by this API.
        # @example get /api/sushi
        # @return [ActionDispatch::Response] { Description: <string> }
        #   (See ./app/views/api/sushi/v5/service/sushi.json.jbuilder for details)
        def sushi
          @description = { Description: "COUNTER Usage Reports for Fulcrum platform." }
        end

        # This resource returns the current status of the reporting service(s) supported by this API.
        # @example get /api/sushi/status?customer_id=String&platform=String
        # @param [Hash] params { customer_id: String, platform: String }
        # @return [ActionDispatch::Response] [ SwaggerClient::SUSHIServiceStatus ]
        #   (See ./app/views/api/sushi/v5/service/status.json.jbuilder for details)
        # Note: customer_id required
        def status
          customer_id = params[:customer_id]
          return head :not_found if customer_id.blank?
          platform = params[:platform] || 'fulcrum'
          return head :not_found unless /fulcrum/i.match?(platform)
          requestor_id = current_user.id
          return head :unauthorized unless current_user.platform_admin?
          @status = SushiService.new(customer_id, platform, requestor_id).status
        end

        # This resource returns the list of consortium members related to a Customer_ID.
        # @example get /api/sushi/members?customer_id=String&platform=String
        # @param [Hash] params { customer_id: String, platform: String }
        # @return [ActionDispatch::Response] [ SwaggerClient::SUSHIConsortiumMemberList ]
        #   (See ./app/views/api/sushi/v5/service/members.json.jbuilder for details)
        # Note: customer_id required
        def members
          customer_id = params[:customer_id]
          return head :not_found if customer_id.blank?
          platform = params[:platform] || 'fulcrum'
          return head :not_found unless /fulcrum/i.match?(platform)
          requestor_id = current_user.id
          return head :unauthorized unless current_user.platform_admin?
          @members = SushiService.new(customer_id, platform, requestor_id).members
        end

        # This resource returns the list of reports related to a Customer_ID.
        # @example get /api/sushi/reports?customer_id=String&platform=String&search=String
        # @param [Hash] params { customer_id: String, platform: String, search: String }
        # @return [ActionDispatch::Response] [ SwaggerClient::SUSHIReportList ]
        #   (See ./app/views/api/sushi/v5/service/reports.json.jbuilder for details)
        # Note: customer_id required
        def reports
          customer_id = params[:customer_id]
          return head :not_found if customer_id.blank?
          platform = params[:platform] || 'fulcrum'
          return head :not_found unless /fulcrum/i.match?(platform)
          requestor_id = current_user.id
          return head :unauthorized unless current_user.platform_admin?
          @reports = SushiService.new(customer_id, platform, requestor_id).reports(params[:search])
        end
      end
    end
  end
end
