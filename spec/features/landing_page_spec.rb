require 'rails_helper'

feature 'Main landing page' do
  scenario 'loads with no errors' do
    visit root_path
    expect(page).to have_content 'For Authors'
    expect(page).to have_content 'Sign Up For Updates'
  end
end
