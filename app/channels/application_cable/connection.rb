# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def session_id
      Rails.logger.debug { "ActionCable::Connection session is: #{@request.session.id}" }
      @request.session.id
    end
  end
end
