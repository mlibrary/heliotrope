# frozen_string_literal: true

module API
  class TokensController < API::ApplicationController
    respond_to :json

    def show
      @token = Token.new(current_user&.token)
    end
  end
end
