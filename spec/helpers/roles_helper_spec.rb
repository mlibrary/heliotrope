# frozen_string_literal: true

require 'rails_helper'

describe RolesHelper, type: :helper do
  describe "#roles_for_select" do
    it 'works' do
      expect(roles_for_select).to eq({ "Admin" => "admin", "Editor" => "editor", "Analyst" => "analyst" })
    end
  end
end
