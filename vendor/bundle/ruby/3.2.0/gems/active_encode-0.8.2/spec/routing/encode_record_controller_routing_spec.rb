# frozen_string_literal: true
require 'rails_helper'

describe ActiveEncode::EncodeRecordController, type: :routing do
  routes { ActiveEncode::Engine.routes }

  it "routes to the show action" do
    expect(get: encode_record_path(1)).to route_to(controller: "active_encode/encode_record", action: "show", id: "1")
  end
end
