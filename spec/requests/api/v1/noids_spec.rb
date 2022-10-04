# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Noids", type: :request do
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end
  let(:response_body) { JSON.parse(@response.body) }

  context 'unauthorized' do
    it 'returns unauthorized' do
      get api_noids_path, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'authorized' do
    before { allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil) }

    describe "GET /api/v1/noids" do # index
      context "default" do
        let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }

        before do
          ActiveFedora::SolrService.add(mono_doc.to_h)
          ActiveFedora::SolrService.commit
        end

        it "returns all noids" do
          get api_noids_path, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to match_array([{ "id" => "mono" }])
        end
      end

      context "by isbn" do
        let(:mono_doc) do
          ::SolrDocument.new(id: 'monoisbn',
                             has_model_ssim: ['Monograph'],
                             isbn_tesim: ["978-0-472-13189-1 (hardcover)", "978-0-472-12665-1 (ebook)"])
        end
        let(:no_match_doc) do
          ::SolrDocument.new(id: 'nomatch',
                             has_model_ssim: ['Monograph'],
                             isbn_tesim: ["978-0-472-00000-0 (hardcover)", "978-0-472-99999-9 (ebook)"])
        end

        before do
          ActiveFedora::SolrService.add(mono_doc.to_h, no_match_doc.to_h)
          ActiveFedora::SolrService.commit
        end

        it "returns the correct noid(s)" do
          get api_noids_path, params: { isbn: "978-0-472-12665-1" }, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to match_array([{ "id" => "monoisbn" }])
        end
      end

      context "by doi" do
        let(:mono_doc) do
          ::SolrDocument.new(id: 'monodoi',
                             has_model_ssim: ['Monograph'],
                             doi_ssim: ["10.3998/mpub.7275146"])
        end
        let(:no_match_doc) do
          ::SolrDocument.new(id: 'nomatch',
                             has_model_ssim: ['Monograph'],
                             doi_ssim: ["10.3998/mpub.9574733"])
        end

        before do
          ActiveFedora::SolrService.add(mono_doc.to_h, no_match_doc.to_h)
          ActiveFedora::SolrService.commit
        end

        it "returns the correct noid(s)" do
          get api_noids_path, params: { doi: "10.3998/mpub.7275146" }, headers: headers
          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(response_body).to match_array([{ "id" => "monodoi" }])
        end
      end

      context "by identifier" do
        let(:mono_doc) do
          ::SolrDocument.new(id: 'monoid',
                             has_model_ssim: ['Monograph'],
                             identifier_tesim: ["bar_number:S1234", "heb_id:heb99999.0001.001"])
        end
        let(:no_match_doc) do
          ::SolrDocument.new(id: 'nomatch',
                             has_model_ssim: ['Monograph'],
                             identifier_tesim: ["bar_number:S0987", "heb_id:heb10000.0001.001"])
        end

        before do
          ActiveFedora::SolrService.add(mono_doc.to_h, no_match_doc.to_h)
          ActiveFedora::SolrService.commit
        end

        context "bar number" do
          it "returns the correct noid(s)" do
            get api_noids_path, params: { identifier: "bar_number:S1234" }, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body).to match_array([{ "id" => "monoid" }])
          end
        end

        context "hebid" do
          it "returns the correct noid(s)" do
            get api_noids_path, params: { identifier: "heb_id:heb99999.0001.001" }, headers: headers
            expect(response.content_type).to eq("application/json")
            expect(response).to have_http_status(:ok)
            expect(response_body).to match_array([{ "id" => "monoid" }])
          end
        end
      end
    end
  end
end
