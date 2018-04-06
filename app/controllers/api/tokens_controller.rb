# frozen_string_literal: true

module API
  class TokensController < API::ApplicationController
    respond_to :json

    def show
      render json: { token: 'token' }, status: :ok
    end
  end
end
