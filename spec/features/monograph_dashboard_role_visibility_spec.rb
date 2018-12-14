# frozen_string_literal: true

require 'rails_helper'

describe 'A monograph deposited by one user' do
  let(:depositor) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: 'umich') }
  let(:press_admin) { create(:press_admin, press: press) }
  let(:monograph) {
    create(:monograph, title: ['My New Book'],
                       press: press.subdomain,
                       user: depositor,
                       edit_groups: ['umich_admin'])
  }

  before { monograph.save! }

  it "can be seen in the dashboard by other users who have edit access" do
    # This is mostly testing app/search_builders/hyrax/my/search_builder.rb which
    # is modified from what was in hyrax
    login_as press_admin
    visit '/dashboard/my/works'
    # In vanilla hyrax users can only see works they've deposited
    # In heliotrope they can see monographs they have edit access to as well
    expect(page).to have_content("My New Book")
  end
end
