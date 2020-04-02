# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressPresenter do
  context "a valid PressPresenter" do
    subject { described_class.for(press.subdomain) }

    describe "#google_analytics" do
      context "when a press has a google_analytics id" do
        let(:press) { create(:press, subdomain: "readreadread", google_analytics: '1-XX') }

        it "returns the ga id" do
          expect(subject.google_analytics).to eq("1-XX")
        end
      end
    end

    describe "#google_analytics_url" do
      context "when a press has a google_analytics URL" do
        let(:press) { create(:press, subdomain: "readreadread", google_analytics_url: 'https://www.example.com/GA/readreadread') }

        it "returns the ga URL" do
          expect(subject.google_analytics_url).to eq('https://www.example.com/GA/readreadread')
        end
      end
    end

    describe "#readership_map_url" do
      context "when a press has a readership map URL" do
        let(:press) { create(:press, subdomain: "readreadread", readership_map_url: 'https://www.example.com/Map/readreadread') }

        it "returns the map URL" do
          expect(subject.readership_map_url).to eq('https://www.example.com/Map/readreadread')
        end
      end
    end

    describe "#restricted_message" do
      let(:press) { create(:press, subdomain: "blah", restricted_message: "<b>No. Just No.</b>") }

      it "returns the restricted_message" do
        expect(subject.restricted_message).to eq "<b>No. Just No.</b>"
      end
    end

    describe "when a child press has a parent" do
      let(:parent_press) {
        create(:press, subdomain: "blue",
                       name: "Blue Press",
                       logo_path: Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')), 'image/jpg'),
                       description: "This is Blue Press",
                       press_url: "http://blue.com",
                       google_analytics: "GA-ID-BLUE",
                       google_analytics_url: 'https://www.example.com/GA/readreadread',
                       typekit: "BLUE-TYPEKIT",
                       footer_block_a: "blue-footer-a",
                       footer_block_b: "blue-footer-b",
                       footer_block_c: "blue-footer-c",
                       parent_id: nil)
      }
      let(:press) {
        create(:press, subdomain: "maize",
                       name: "Maize Press",
                       logo_path: Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'miranda.jpg')), 'image/jpg'),
                       description: "This is Maize Press",
                       press_url: "http://blue.com/maize",
                       google_analytics: nil, # factorybot will fake a ga-id without this
                       google_analytics_url: nil,
                       parent_id: parent_press.id)
      }

      context "when the child is missing a field" do
        it "uses the parent's field" do
          expect(subject.footer_block_a).to eq parent_press.footer_block_a
          expect(subject.footer_block_b).to eq parent_press.footer_block_b
          expect(subject.footer_block_c).to eq parent_press.footer_block_c
          expect(subject.google_analytics).to eq parent_press.google_analytics
          expect(subject.google_analytics_url).to eq parent_press.google_analytics_url
          expect(subject.typekit).to eq parent_press.typekit
        end
        it "does not use the parent's name, since a name is required for all presses" do
          expect(subject.name).to eq press.name
        end
      end

      describe "#press_subdomains" do
        it "returns the press's subdomains in the right order, child then parent" do
          expect(subject.press_subdomains).to eq [press.subdomain, parent_press.subdomain]
        end
      end
    end

    describe "#all_google_analytics with two GA ids" do
      let(:parent_press) { create(:press, subdomain: "blue", google_analytics: "GA-ID-BLUE") }
      let(:press) { create(:press, subdomain: "maize", google_analytics: "GA-ID-MAIZE", parent_id: parent_press.id) }

      it "returns both Google analytics ids" do
        expect(subject.all_google_analytics).to match_array [press.google_analytics, parent_press.google_analytics]
      end
    end
  end

  context "a invalid PressPresenter aka a PressPresenterNullObject" do
    subject { described_class.for(nil) }

    it "is a PressPresenterNullObject" do
      expect(subject.is_a? PressPresenter).to be false
      expect(subject.is_a? PressPresenterNullObject).to be true
    end

    describe "#present?" do
      # Is it too weird to override .present?
      # It is very useful in the views to do this, but it's a little much maybe
      it "is not present?" do
        expect(subject.present?).to be false
      end
    end

    describe "#subdomain" do
      it "is an empty string" do
        expect(subject.subdomain).to be ""
      end
    end

    describe "#press" do
      it "is an empty string" do
        expect(subject.press).to be ""
      end
    end

    describe "#press_subdomains" do
      it "is an empty array" do
        expect(subject.press_subdomains).to eq []
      end
    end

    describe "#all_google_analytics" do
      it "is an empty array" do
        expect(subject.all_google_analytics).to eq []
      end
    end

    context "All other PressPresenter methods are cuaght by method_missing" do
      it "returns an empty string" do
        expect(subject.footer_block_a).to eq ""
        expect(subject.some_kind_of_nonsense).to eq ""
      end
    end
  end
end
