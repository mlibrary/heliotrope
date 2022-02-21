# frozen_string_literal: true

module API
  # Namespace for the public facing SUSHI API REST endpoints
  module Sushi
    module V5
      # Reports Controller
      class ReportsController < API::ApplicationController
        # @example get /api/sushi/reports/:id?customer_id=String&platform=String
        # @param [Hash] params { id: /dr|dr_d1|dr_d2|ir|ir_a1|ir_m1|pr|pr_p1|tr|tr_b1|tr_b2|tr_b3|tr_j1|tr_j2|tr_j3|tr_j4/, customer_id: String, platform: String }
        # @return [ActionDispatch::Response] { ::SwaggerClient::COUNTER<Platform|Database|Title|Item>Report }
        #   (See ./app/views/api/sushi/v5/reports/show.json.jbuilder for details)
        def show
          customer_id = params[:customer_id]
          return head :not_found if customer_id.blank?
          platform_id = params[:platform]
          return head :not_found if platform_id.blank?
          requestor_email = current_user.email
          return head :unauthorized unless current_user.platform_admin?
          @report = SushiService.new(customer_id, platform_id, requestor_email).report(params[:id])
        end
      end
    end
  end
end
