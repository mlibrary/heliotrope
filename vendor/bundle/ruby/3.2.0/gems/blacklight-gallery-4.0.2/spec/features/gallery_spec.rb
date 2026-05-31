require 'spec_helper'

describe "Gallery view", :type => :feature do
  before { visit search_catalog_path :q => 'medicine', :view => 'gallery' }

  it "should display results in a galley view" do
    expect(page).to have_selector("#documents.documents-gallery")
    expect(page).to have_selector(".caption", text: "Strong Medicine speaks")
  end
end
