# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Presses", type: :request do
  def press_obj(press:)
    {
      "id" => press.id,
      "subdomain" => press.subdomain,
      "name" => press.name,
      "url" => press_url(press, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:press) { create(:press) }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_find_press_path, params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_presses_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_press_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe 'GET /api/v1/press' do # find
      it 'non existing not found' do
        get api_find_press_path, params: { subdomain: 'subdomain' }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(Press.count).to eq(0)
      end

      it 'existing ok' do
        get api_find_press_path, params: { subdomain: press.subdomain }, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(press_obj(press: press))
        expect(Press.count).to eq(1)
      end
    end

    describe "GET /api/v1/presses" do # index
      it 'empty ok' do
        get api_presses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Press.count).to eq(0)
      end

      it 'press ok' do
        press
        get api_presses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([press_obj(press: press)])
        expect(Press.count).to eq(1)
      end

      it 'presses ok' do
        press
        new_press = create(:press)
        get api_presses_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([press_obj(press: press), press_obj(press: new_press)])
        expect(Press.count).to eq(2)
      end
    end

    describe "GET /api/v1/presses/:id" do # show
      it 'non existing not_found' do
        get api_press_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Press")
        expect(Press.count).to eq(0)
      end

      it 'existing ok' do
        get api_press_path(press.id), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq(press_obj(press: press))
        expect(Press.count).to eq(1)
      end
    end
  end
end
