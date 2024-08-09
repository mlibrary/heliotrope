# frozen_string_literal: true

class LongRunningRequestsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "long_running_requests_channel_#{connection.session_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
