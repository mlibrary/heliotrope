require 'spec_helper'

describe "Masonry view", :type => :feature do
  before { visit search_catalog_path :q => 'medicine', :view => 'masonry' }

  it "should display results in a galley view" do
    expect(page).to have_selector("#documents.documents-masonry")
    expect(page).to have_selector('.document .caption', text: "Strong Medicine speaks", visible: false)
  end
end
