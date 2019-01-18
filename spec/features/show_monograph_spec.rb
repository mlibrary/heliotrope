# frozen_string_literal: true

require 'rails_helper'

describe "Show a monograph" do
  let(:creator) { ['Shakespeare, William'] }
  let(:first_name) { 'William' }
  let(:user) { create(:platform_admin) }

  let!(:monograph) { create(:public_monograph, creator: creator) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    login_as user
  end

  it do
    visit monograph_show_path(monograph)
    expect(page).to have_link 'Shakespeare, William'
  end
end
