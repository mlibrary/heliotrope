# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monographs", type: :request do
  def monograph_obj(monograph:)
    {
      "id" => monograph.id,
      "title" => monograph.title,
      "url" => monograph_catalog_url(monograph, format: :json)
    }
  end
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:monograph) { create(:monograph) }
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it { get api_monographs_path, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_press_monographs_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_monograph_path(1), headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_monograph_extract_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
    it { get api_monograph_manifest_path(1), params: {}, headers: headers; expect(response).to have_http_status(:unauthorized) } # rubocop:disable Style/Semicolon
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe "GET /api/v1/monographs" do # index
      it 'empty ok' do
        get api_monographs_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Monograph.count).to eq(0)
      end

      it 'monograph ok' do
        monograph
        get api_monographs_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([monograph_obj(monograph: monograph)])
        expect(Monograph.count).to eq(1)
      end

      it 'monographs ok' do
        monograph
        new_monograph = create(:monograph)
        get api_monographs_path, headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([monograph_obj(monograph: monograph), monograph_obj(monograph: new_monograph)])
        expect(Monograph.count).to eq(2)
      end
    end

    describe "GET /api/v1/presses/:press_id/monographs" do # index
      it 'not_found' do
        monograph
        get api_press_monographs_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveRecord::RecordNotFound: Couldn't find Press")
        expect(Monograph.count).to eq(1)
      end

      it 'empty ok' do
        monograph
        press = create(:press)
        get api_press_monographs_path(press), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to eq([])
        expect(Monograph.count).to eq(1)
      end

      it 'monograph ok' do
        monograph
        get api_press_monographs_path(monograph.press), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([monograph_obj(monograph: monograph)])
        expect(Monograph.count).to eq(1)
      end

      it 'monographs ok' do
        monograph
        new_monograph = create(:monograph, press: monograph.press)
        get api_press_monographs_path(monograph.press), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(response_body).to match_array([monograph_obj(monograph: monograph), monograph_obj(monograph: new_monograph)])
        expect(Monograph.count).to eq(2)
      end
    end

    describe "GET /api/v1/monographs/:id" do # show
      it 'non existing not_found' do
        get api_monograph_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveFedora::ObjectNotFoundError: Couldn't find Monograph")
        expect(Monograph.count).to eq(0)
      end

      it 'existing ok' do
        get api_monograph_path(monograph.id), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect([response_body]).to match_array([monograph_obj(monograph: monograph)])
        expect(Monograph.count).to eq(1)
      end
    end

    describe "GET /api/v1/monographs/:id/extract" do # extract
      it 'non existing not_found' do
        get api_monograph_extract_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveFedora::ObjectNotFoundError: Couldn't find Monograph")
        expect(Monograph.count).to eq(0)
      end

      it 'existing ok' do
        get api_monograph_extract_path(monograph.id), headers: headers
        expect(response.content_type).to eq("application/zip")
        expect(response).to have_http_status(:ok)
        # expect(response.body).to eq(Export::Exporter.new(monograph.id).extract(dir))
        expect(response.body[0]).to eq('P')
        expect(Monograph.count).to eq(1)
      end
    end

    describe "GET /api/v1/monographs/:id/manifest" do # manifest
      it 'non existing not_found' do
        get api_monograph_manifest_path(1), headers: headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(response_body[:exception.to_s]).to include("ActiveFedora::ObjectNotFoundError: Couldn't find Monograph")
        expect(Monograph.count).to eq(0)
      end

      it 'existing ok' do
        get api_monograph_manifest_path(monograph.id), headers: headers
        expect(response.content_type).to eq("text/csv")
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(Export::Exporter.new(monograph.id).export)
        expect(Monograph.count).to eq(1)
      end
    end
  end
end
