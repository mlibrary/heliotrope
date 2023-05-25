# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "StaticMetadata", type: :request do
  # All this really is is a mapping of the file system
  # Instead of letting apache do it, we're reproducing it in the controller
  # see HELIO-4408
  let(:test_root) { File.join(Settings.scratch_space_path, 'spec', 'public', 'products', 'umpebc', 'kbart') }

  before do
    FileUtils.mkdir_p(test_root)
    # this is "bad" but we just want to use the testing file system. It's overriding a simple private method.
    allow_any_instance_of(StaticMetadataController).to receive(:root_dir).and_return(Rails.root.join("tmp", "spec", "public", "products"))
  end

  after do
    FileUtils.rm_rf(test_root)
  end

  describe "GET /products" do
    it "returns ok" do
      get "/products"
      expect(response).to have_http_status(:ok)
    end
  end

  context "with the correct path status ok" do
    describe "/products/umpebc" do
      it "returns ok" do
        get "/products/umpebc"
        expect(response).to have_http_status(:ok)
      end
    end

    describe "/products/umpebc/kbart" do
      it "returns ok" do
        get "/products/umpebc/kbart"
        expect(response).to have_http_status(:ok)
      end
    end

    # We're not going to test the actual file request/response here like for
    # /products/umpebc/kbart/UMPEBC_2011_2022-01-01.csv
    # In production Apache will serve this content directly. Rails doesn't touch it.
  end

  context "with the incorrect path" do
    describe "/products/something" do
      it "still returns :ok, but there's a message that there are no files found in the template" do
        get "/products/something"
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
