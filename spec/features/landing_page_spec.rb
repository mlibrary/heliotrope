require 'rails_helper'

feature 'Main landing page' do
  before { Press.destroy_all }
  let!(:press) { create :press }

  scenario 'loads with no errors' do
    visit root_path
    expect(page).to have_link press.name
  end
end
