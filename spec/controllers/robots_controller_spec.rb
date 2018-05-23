# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RobotsController, type: :controller do
  describe "#robots" do
    context "with the test environment" do
      before { get :robots }
      it "denies robots" do
        expect(response.body).to match(/\nUser\-Agent: \*\n/)
        expect(response.body).to match(/\nDisallow: \/\n/)
      end
    end

    context "on preview (or staging or testing)" do
      before do
        allow(Rails).to receive(:env).and_return("production")
        allow(Socket).to receive(:gethostname).and_return("nectar.umdl.umich.edu")
        get :robots
      end
      it "denies robots" do
        expect(response.body).to match(/\nUser\-Agent: \*\n/)
        expect(response.body).to match(/\nDisallow: \/\n/)
      end
    end

    context "on production" do
      before do
        allow(Rails).to receive(:env).and_return("production")
        allow(Socket).to receive(:gethostname).and_return("anything_but_nectar")
        get :robots
      end
      it "allows robots" do
        expect(response.body).to match(/\n# User\-Agent: \*\n/)
        expect(response.body).to match(/\n# Disallow: \/\n/)
        expect(response.body).to match(/Sitemap: https:\/\/fulcrum\.org\/sitemaps\/sitemap\.xml\.gz/)
      end
    end
  end
end
