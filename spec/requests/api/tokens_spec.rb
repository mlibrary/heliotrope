# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Tokens", type: :request do
  def user_obj(user:)
    {
      "id" => user.id,
      "email" => user.email,
      "url" => user_url(user.id, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:response_hash) { HashWithIndifferentAccess.new JSON.parse(@response.body) }

  it 'missing authorization header' do
    get api_token_path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).not_to be_empty
    expect(response_hash[:exception]).not_to be_empty
    expect(response_hash[:exception]).to include("RuntimeError: HTTP Authorization request header blank.")
  end

  context 'authorization header' do
    before { headers["AUTHORIZATION"] = token }

    context 'missing token' do
      let(:token) {}

      it do
        expect(token).to be_nil
        get api_token_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).not_to be_empty
        expect(response_hash[:exception]).not_to be_empty
        expect(response_hash[:exception]).to include("RuntimeError: HTTP Authorization request header blank.")
      end
    end

    context 'token' do
      let(:token) { user.token }
      let(:user) { build(:user) }

      context 'user not found' do
        it do
          expect(token).to eq(user.token)
          get api_token_path, headers: headers
          expect(response).to have_http_status(:unauthorized)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("RuntimeError: User #{user.email} not found.")
        end
      end

      context 'user' do
        let(:user) { create(:user) }

        it do
          expect(token).to eq(user.token)
          get api_token_path, headers: headers
          expect(response).to have_http_status(:unauthorized)
          expect(response.body).not_to be_empty
          expect(response_hash[:exception]).not_to be_empty
          expect(response_hash[:exception]).to include("RuntimeError: User #{user.email} not a platform administrator.")
        end
      end

      context 'platform administrator' do
        let(:user) { create(:platform_admin) }

        it do
          expect(token).to eq(user.token)
          get api_token_path, headers: headers
          expect(response).to have_http_status(:ok)
          expect(response_hash[:user]).to eq(user_obj(user: user))
        end

        context 'unsigned token' do
          let(:token) { JWT.encode({ email: user.email, pin: user.encrypted_password }, nil, 'none') }

          it do
            expect(token).not_to eq(user.token)
            get api_token_path, headers: headers
            expect(response).to have_http_status(:unauthorized)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("JWT::DecodeError: Not enough or too many segments")
          end
        end

        context 'new token' do
          it do
            expect(token).to eq(user.token)
            user.tokenize!
            expect(token).not_to eq(user.token)
            get api_token_path, headers: headers
            expect(response).to have_http_status(:unauthorized)
            expect(response.body).not_to be_empty
            expect(response_hash[:exception]).not_to be_empty
            expect(response_hash[:exception]).to include("RuntimeError: User #{user.email} pin no longer valid.")
          end
        end
      end
    end
  end
end
