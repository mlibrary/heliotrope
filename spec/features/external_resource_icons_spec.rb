# frozen_string_literal: true

require 'rails_helper'

feature "Monograph Catalog Facets" do
  before do
    stub_out_redis
  end

  let(:cover) { create(:public_file_set) }

  context "external resource image icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource: 'yes', resource_type: ["image"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "image shows picture icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
      expect(page).to_not have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
    end
    scenario "image shows picture icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
      expect(page).to_not have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
    end
  end

  context "external resource file icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource: 'yes', resource_type: ["text"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "text shows file icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_css('span.glyphicon-file', count: 1)
      expect(page).to_not have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
    end
    scenario "text shows file icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_css('span.glyphicon-file', count: 1)
      expect(page).to_not have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
    end
  end

  context "external resource video icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource: 'yes', resource_type: ["video"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "video shows film icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
    end
    scenario "video shows film icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_css('span.glyphicon-film')
      expect(page).to_not have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
    end
  end

  context "external resource audio icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource: 'yes', resource_type: ["audio"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "audio shows 'volume up' icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
      expect(page).to_not have_css('span.glyphicon-film')
    end
    scenario "audio shows 'volume up' icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_css('span.glyphicon-volume-up')
      expect(page).to_not have_css('span.glyphicon-picture')
      expect(page).to have_css('span.glyphicon-file', count: 0)
      expect(page).to_not have_css('span.glyphicon-film')
    end
  end
end
