# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Show a monograph", type: :system do # rubocop:disable RSpec/DescribeClass
  let(:last_name) { 'Shakespeare' }
  let(:first_name) { 'William' }

  let!(:monograph) { create(:public_monograph, creator_family_name: last_name, creator_given_name: first_name) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  # This spec actually just tests vanilla hyrax so we don't really need it.
  # But it's an example of how to use axe-matcher's "be_accessible", system specs, the
  # chrome webdriver and turning automatic screenshots off

  def take_failed_screenshot
    false
  end

  pending "be_accessible fails, when it's fixed remove the 'pending'" do
    visit monograph_show_path(monograph)
    expect(page).to have_link 'Shakespeare, William'
    expect(page).to be_accessible
  end
end
