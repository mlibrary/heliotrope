# frozen_string_literal: true

module API
  module V1
    class CrossrefRegistrationsController < API::ApplicationController
      def create
        file = params[:fname].read
        resp = Crossref::Register.new(file).post

        if resp.code == 200 && resp.body.match(/SUCCESS/)
          render json: { body: resp.body }, status: :ok
        else
          # Crossref will often send back 200 :ok status codes
          # even if there are problems. It seems like the only reliable
          # indication there's an error is in the html body. Which is
          # not great.
          render json: { body: resp.body }, status: :bad_request
        end
      end

      private
        # Only log exceptions, we do crossref specific logging
        # in the CrossrefSubmissionLog from Crossref::Register
        def log_request_response(exception = nil)
          super(exception) if exception.present?
        end

        def crossref_registrations_params
          params.require(:crossref_registrations).permit(:fname)
        end
    end
  end
end
