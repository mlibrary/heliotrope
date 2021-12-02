# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_ga.html.erb' do
  let(:press) { create(:press, subdomain: 'bookcircus', google_analytics: 'TEST-PRESS-ID') }

  before do
    view.extend PressHelper
    allow(Settings).to receive(:host).and_return("www.fulcrum.org")
    controller.instance_eval do
      def current_institutions
        [ Greensub::Institution.new(identifier: 1) ]
      end
    end
  end

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
      # create this above where the factory can fill out required fields
      @press = press
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

  context "when the user is Staff" do
    before do
      controller.instance_eval do
        def current_institutions
          [
            Greensub::Institution.new(identifier: 490),
            Greensub::Institution.new(identifier: 1)
          ]
        end
      end
    end

    it "renders no google analytics javascript" do
      Rails.application.secrets.google_analytics_id = "TEST-ID"
      render
      expect(rendered).not_to match(/javascript/)
    end
  end

  context "when the request is from a crawler (that has an Institution like LOCKSS/CLOCKSS or Google Scholar)" do
    before do
      controller.instance_eval do
        def current_institutions
          [
            Greensub::Institution.new(identifier: 2402, name: "Google Scholar")
          ]
        end
      end
    end

    it "renders no google analytics javascript" do
      Rails.application.secrets.google_analytics_id = "TEST-ID"
      render
      expect(rendered).not_to match(/javascript/)
    end
  end
end
