# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees Grants", type: :request do
  let(:headers) do
    {
      "ACCEPT" => "application/json, application/vnd.heliotrope.v1+json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:product) { create(:product) }
  let(:individual) { create(:individual) }
  let(:institution) { create(:institution) }

  before do
    allow_any_instance_of(API::ApplicationController).to receive(:authorize_request).and_return(nil)
    Checkpoint::DB.db[:permits].delete
  end

  it 'works' do
    expect(Grant.count).to eq(0)

    # individual

    put api_product_individual_path(product, individual), headers: headers
    expect(Grant.count).to eq(1)
    delete api_product_individual_path(product, individual), headers: headers
    expect(Grant.count).to eq(0)

    # institution

    put api_product_institution_path(product, institution), headers: headers
    expect(Grant.count).to eq(1)
    delete api_product_institution_path(product, institution), headers: headers
    expect(Grant.count).to eq(0)

    # individual and institution

    put api_product_individual_path(product, individual), headers: headers
    expect(Grant.count).to eq(1)
    put api_product_institution_path(product, institution), headers: headers
    expect(Grant.count).to eq(2)
    delete api_product_individual_path(product, individual), headers: headers
    expect(Grant.count).to eq(1)
    delete api_product_institution_path(product, institution), headers: headers
    expect(Grant.count).to eq(0)
  end
end
