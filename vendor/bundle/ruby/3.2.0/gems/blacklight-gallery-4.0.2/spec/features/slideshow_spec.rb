require 'spec_helper'

describe "Slideshow", :js, :type => :feature do

  it "should open when one of the grid panes are clicked" do
    visit search_catalog_path( :q => 'medicine', :view => 'slideshow' )
    expect(page).to have_content "You searched for:"
    within ".view-type" do
      click_link "Slideshow"
    end

    find('.grid [data-slide-to="0"]').click
  end

end
