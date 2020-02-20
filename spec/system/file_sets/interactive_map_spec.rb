# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'File Sets -> Interactive Map', type: :system, browser: true do
  let(:monograph) do
    create(:public_monograph) do |m|
      m.ordered_members << file_set
      m.save!
      file_set.save!
      m
    end
  end
  let(:file_set) { create(:public_file_set) }
  let(:user) { create(:platform_admin) }

  before do
    login_as user
    monograph
    allow(UnpackJob).to receive(:perform_later).with(file_set.id, 'interactive_map')
  end

  it 'does not unpack' do
    visit hyrax_file_set_path(file_set)
    click_link 'Edit'
    find '#descriptions_display', wait: 10
    fill_in 'Resource Type', with: 'map'
    click_on 'Update Attached File'
    find '#tab-info', wait: 10
    expect(page).to have_content "The file #{Sighrax.from_noid(file_set.id).title} has been updated."
    expect(UnpackJob).not_to have_received(:perform_later).with(file_set.id, 'interactive_map')
  end

  it 'unpacks' do
    visit hyrax_file_set_path(file_set)
    click_link 'Edit'
    find '#descriptions_display', wait: 10
    fill_in 'Resource Type', with: 'interactive map'
    click_on 'Update Attached File'
    find '#tab-info', wait: 10
    expect(page).to have_content "The file #{Sighrax.from_noid(file_set.id).title} has been updated."
    expect(UnpackJob).to have_received(:perform_later).with(file_set.id, 'interactive_map')
  end

  it 'unpacks once' do
    visit hyrax_file_set_path(file_set)
    click_link 'Edit'
    find '#descriptions_display', wait: 10
    fill_in 'Resource Type', with: 'interactive map'
    click_on 'Update Attached File'
    find '#tab-info', wait: 10
    expect(page).to have_content "The file #{Sighrax.from_noid(file_set.id).title} has been updated."
    click_link 'Edit'
    find '#descriptions_display', wait: 10
    fill_in 'Title', with: 'Interactive Map'
    click_on 'Update Attached File'
    find '#tab-info', wait: 10
    expect(page).to have_content "The file #{Sighrax.from_noid(file_set.id).title} has been updated."
    expect(UnpackJob).to have_received(:perform_later).with(file_set.id, 'interactive_map').once
  end
end
