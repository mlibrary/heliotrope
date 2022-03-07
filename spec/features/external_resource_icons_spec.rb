# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Facets" do
  before do
    stub_out_redis
    stub_out_irus
  end

  let(:cover) { create(:public_file_set) }

  context "external resource image icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/1', resource_type: ["image"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "image shows image icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/image")]')
    end
    it "image shows image icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/image")]')
    end
  end

  context "external resource file icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/2', resource_type: ["text"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "text shows file icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/text")]')
    end
    it "text shows file icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/text")]')
    end
  end

  context "external resource video icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/3', resource_type: ["video"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "video shows video icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/video")]')
    end
    it "video shows video icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/video")]')
    end
  end

  context "external resource audio icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/4', resource_type: ["audio"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "audio shows audio icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/audio")]')
    end
    it "audio shows audio icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/audio")]')
    end
  end

  context "external resource map icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/4', resource_type: ["map"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "map shows map icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/map")]')
    end
    it "map shows map icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/map")]')
    end
  end

  context "external resource interactive map icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/4', resource_type: ["interactive map"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "map shows map icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/map")]')
    end
    it "map shows map icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/map")]')
    end
  end

  context "external resource default icons" do
    let(:monograph) { create(:public_monograph, title: ["External"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, external_resource_url: 'https://example.com/4', resource_type: ["mystery"]) }

    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
      cover.save!
      file_set1.save!
    end

    it "unknown shows default icon in list view" do
      visit monograph_catalog_path(monograph.id)
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/default")]')
    end
    it "unknown shows default icon in gallery view" do
      visit monograph_catalog_path(monograph.id)
      click_link "Gallery"
      expect(page).to have_xpath('//img[@class="svgicon"]')
      expect(page).to have_xpath('//img[contains(@src,"svgicon/default")]')
    end
  end
end
