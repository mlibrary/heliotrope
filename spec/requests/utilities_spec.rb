# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Utilities", type: :request do
  describe "GET /whoami" do
    let(:headers) do
      {
        'HTTP_USER_AGENT' => 'expected_user_agent',
        'REMOTE_HOST' => 'expected_remote_host',
        'REMOTE_ADDR' => 'expected_remote_addr',
        'REMOTE_USER' => 'expected_remote_user',
        'HTTP_X_FORWARDED_FOR' => 'expected_x_forwarded_for'
      }
    end

    it do
      get whoami_utility_path, params: { expected_note: nil }, headers: headers
      expect(response).to have_http_status(:success)
      expect(response.body).to include('expected_user_agent')
      expect(response.body).to include('expected_remote_host')
      expect(response.body).to include('expected_remote_addr')
      expect(response.body).not_to include('expected_remote_user') # FYI: REMOTE_USER is nil!  Don't know why. :(
      expect(response.body).to include('expected_x_forwarded_for')
      expect(response.body).to include('expected_note')
    end

    context 'without note' do
      it do
        get whoami_utility_path, params: {}, headers: headers
        expect(response).to have_http_status(:success)
        expect(response.body).to include('expected_user_agent')
        expect(response.body).to include('expected_remote_host')
        expect(response.body).to include('expected_remote_addr')
        expect(response.body).not_to include('expected_remote_user') # FYI: REMOTE_USER is nil!  Don't know why. :(
        expect(response.body).to include('expected_x_forwarded_for')
        expect(response.body).to include('(none)')
      end
    end

    context 'without note or headers' do
      it do
        get whoami_utility_path, params: {}, headers: {}
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('expected_user_agent')
        expect(response.body).not_to include('expected_remote_host')
        expect(response.body).not_to include('expected_remote_addr')
        expect(response.body).not_to include('expected_remote_user')
        expect(response.body).not_to include('expected_x_forwarded_for')
        expect(response.body).to include('(none)')
      end
    end
  end
end
