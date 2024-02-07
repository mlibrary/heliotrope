# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_my_actions.html.erb' do
  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_institutions?).and_return(false)
  end

  context "a platform admin user" do
    let(:user) { create(:platform_admin) }

    before { render }

    it "shows the add content button" do
      expect(rendered).to have_link("Create Monograph")
    end
  end

  context "a press admin for Monographs" do
    let(:press) { create(:press) }
    let(:user) { create(:press_admin, press: press) }

    before { render }

    it "shows the monograph add content button" do
      expect(rendered).to have_link("Create Monograph")
    end
  end

  context "a non-privileged user" do
    let(:user) { create(:user) }

    before { render }

    it "does not show the add content button" do
      expect(rendered).not_to have_link("Create Monograph")
    end
  end
end
