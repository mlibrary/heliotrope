# frozen_string_literal: true

require 'rails_helper'

describe PressHelper, type: :helper do
  describe "#press_presenter" do
    context "with a @press.subdomain" do
      let(:press) { create(:press, subdomain: 'blue') }

      it "is a PressPresenter" do
        @press = press
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with a @presenter.subdomain" do
      let(:press) { create(:press, subdomain: "blue") }
      let(:presenter) { double("presenter", subdomain: press.subdomain) }

      it "is a PressPresenter" do
        @presenter = presenter
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with a @presenter.parent.subdomain" do
      let(:press) { create(:press, subdomain: "blue") }
      let(:file_set_presenter) { double("presenter", parent: monograph_presenter) }
      let(:monograph_presenter) { double("presenter", subdomain: press.subdomain) }

      it "is a PressPresenter" do
        @presenter = file_set_presenter
        expect(press_presenter.is_a?(PressPresenter)).to eq true
        expect(press_presenter.present?).to eq true
      end
    end

    context "with no press" do
      it "is a PressPresenterNullObject" do
        expect(press_presenter.is_a?(PressPresenterNullObject)).to be true
      end

      it "responds to .present? with false" do
        expect(press_presenter.present?).to be false
      end
    end
  end
end
