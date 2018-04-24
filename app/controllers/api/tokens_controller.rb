# frozen_string_literal: true

module API
  # JSON Web Token (JWT) Controller
  class TokensController < API::ApplicationController
    # Token's owner information
    # @return [ActionDispatch::Response] {#current_user}
    #   (See ./app/views/api/tokens/show.json.jbuilder for details)
    def show; end
  end
end
