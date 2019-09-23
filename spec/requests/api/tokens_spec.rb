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

  it 'missing token' do
    get api_token_path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).not_to be_empty
    expect(response_hash[:exception]).not_to be_empty
    expect(response_hash[:exception]).to include("RuntimeError: HTTP Authorization or ApiKey query blank or corrupt.")
  end

  context 'rescue_from' do
    let(:error) { StandardError }

    before do
      allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_raise(error)
      get api_token_path, headers: headers
    end

    it { expect(response).to be_unauthorized }

    context 'ActiveRecord::RecordInvalid' do
      let(:error) { ActiveRecord::RecordInvalid }

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context 'ActiveRecord::RecordNotFound' do
      let(:error) { ActiveRecord::RecordNotFound }

      it { expect(response).to be_not_found }
    end

    context 'log_request_response' do
      let(:api_request) { double('api_request', user: nil, action: nil, path: nil, params: nil, status: nil, exception: nil) }

      before do
        allow(APIRequest).to receive(:new).and_return(api_request)
        allow(api_request).to receive(:user=).with(nil)
        allow(api_request).to receive(:action=).with("GET")
        allow(api_request).to receive(:path=).with("/api/token")
        allow(api_request).to receive(:params=).with("{\"controller\":\"api/tokens\",\"action\":\"show\",\"token\":{}}")
        allow(api_request).to receive(:status=).with(200)
        allow(api_request).to receive(:exception=).with(StandardError)
        allow(api_request).to receive(:save!).and_raise(StandardError)
        allow(Rails.logger).to receive(:error).with("EXCEPTION StandardError API_REQUEST , , , , , ")
        get api_token_path, headers: headers
      end

      it do
        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  context 'authorization header' do
    before { headers["AUTHORIZATION"] = token }

    context 'missing token' do
      let(:token) { }

      it do
        expect(token).to be_nil
        get api_token_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).not_to be_empty
        expect(response_hash[:exception]).not_to be_empty
        expect(response_hash[:exception]).to include("RuntimeError: HTTP Authorization or ApiKey query blank or corrupt.")
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

  context 'apikey query' do
    context 'missing token' do
      let(:token) { }

      it do
        expect(token).to be_nil
        get api_token_path(apikey: token), headers: headers
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).not_to be_empty
        expect(response_hash[:exception]).not_to be_empty
        expect(response_hash[:exception]).to include("RuntimeError: HTTP Authorization or ApiKey query blank or corrupt.")
      end
    end

    context 'token' do
      let(:token) { user.token }
      let(:user) { build(:user) }

      context 'user not found' do
        it do
          expect(token).to eq(user.token)
          get api_token_path(apikey: token), headers: headers
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
          get api_token_path(apikey: token), headers: headers
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
          get api_token_path(apikey: token), headers: headers
          expect(response).to have_http_status(:ok)
          expect(response_hash[:user]).to eq(user_obj(user: user))
        end

        context 'unsigned token' do
          let(:token) { JWT.encode({ email: user.email, pin: user.encrypted_password }, nil, 'none') }

          it do
            expect(token).not_to eq(user.token)
            get api_token_path(apikey: token), headers: headers
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
            get api_token_path(apikey: token), headers: headers
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
