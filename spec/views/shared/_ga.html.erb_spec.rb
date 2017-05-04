# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_ga.html.erb' do
  context "when there's a fulcrum google_analytics_id" do
    it "renders google analytics javascript with fulcrum GA id" do
      Rails.application.secrets.google_analytics_id = "TEST-ID"
      render
      expect(rendered).to match(/TEST-ID/)
    end
  end

  context "when there's a fulcrum google analytics id and a press google analytics id and we're on a press page" do
    it "renders google analytics javascript with the press google analytics id" do
      Rails.application.secrets.google_analytics_id = "TEST-ID"
      @press = Press.create(subdomain: 'bookcircus', google_analytics: 'TEST-PRESS-ID')
      render
      expect(rendered).to match(/TEST-PRESS-ID/)
    end
  end

  context "when there's no fulcrum google analytics id" do
    it "renders no google analytics javascript" do
      Rails.application.secrets.delete :google_analytics_id
      render
      expect(rendered).not_to match(/javascript/)
    end
  end
end
