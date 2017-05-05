# frozen_string_literal: true

require 'rails_helper'

feature "Show a monograph" do
  let(:last_name) { 'Shakespeare' }
  let(:first_name) { 'William' }

  let!(:monograph) { create(:public_monograph, creator_family_name: last_name, creator_given_name: first_name) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  scenario do
    visit monograph_show_path(monograph)
    expect(page).to have_link 'Shakespeare, William'
  end
end
