# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog TOC", type: :system do
  let(:platform_admin) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: subdomain) }
  let(:monograph) { create(:monograph, press: press.subdomain, user: platform_admin, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:file_set, id: '999999999', allow_download: 'no', content: File.open(File.join(fixture_path, epub))) }
  let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

  before do
    stub_out_redis
    monograph.ordered_members << cover
    monograph.ordered_members << file_set
    monograph.save!
    cover.save!
    file_set.save!
    UnpackJob.perform_now(file_set.id, 'epub')
    fr
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  context 'free flow epub' do
    let(:epub) { 'moby-dick.epub' }

    context 'nonheb subdomain' do
      let(:subdomain) { 'nonheb' }

      context 'when authorized' do
        it 'has no buttons' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).not_to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end

      context 'when unauthorized' do
        let(:parent) { Sighrax.factory(monograph.id) }

        before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

        it 'has no buttons' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).not_to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end
    end

    context 'heb subdomain' do
      let(:subdomain) { 'heb' }

      context 'when authorized' do
        it 'has no buttons' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).not_to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end

      context 'when unauthorized' do
        let(:parent) { Sighrax.factory(monograph.id) }

        before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

        it 'has no buttons' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).not_to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end
    end
  end

  context 'page image epub' do
    let(:epub) { 'the-whale.epub' }

    context 'nonheb subdomain' do
      let(:subdomain) { 'nonheb' }

      context 'when authorized' do
        it 'has Read button' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end

      context 'when unauthorized' do
        let(:parent) { Sighrax.factory(monograph.id) }

        before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

        it 'has Read button' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end
        end
      end
    end

    context 'heb subdomain' do
      let(:subdomain) { 'heb' }

      context 'when authorized' do
        it 'has Read and Download buttons' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).to have_xpath(".//span[@title='Read section']")
            expect(page).to have_xpath(".//i[@title='Download section']")
          end
        end
      end

      context 'when unauthorized' do
        let(:parent) { Sighrax.factory(monograph.id) }

        before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

        it 'has Read button' do
          visit monograph_catalog_path(monograph)
          click_on("Table of Contents")
          within("#toc") do
            expect(page).to have_xpath(".//span[@title='Read section']")
            expect(page).not_to have_xpath(".//i[@title='Download section']")
          end

          # Selectors needed for assets/javascripts/application/ga_event_tracking.js
          # If these change, fix here then update ga_event_tracking.js
          expect(page).to have_css('#tab-toc')
          expect(page).to have_css('#tab-stats')
          expect(page).to have_selector('ul.nav.nav-tabs li a', count: 2)
        end
      end
    end
  end
end
