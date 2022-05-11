# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog EPUB TOC", type: :system, browser: true do
  let(:press) { create(:press, interval: interval) }
  let(:monograph) { create(:public_monograph, press: press.subdomain, open_access: open_access, representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  # as of 202103 the EPUB FileSet needs to be public for ToC Read/Download buttons to show, allow_download is not relevant
  let(:file_set) { create(:public_file_set, id: '999999999', allow_download: 'no', content: File.open(File.join(fixture_path, epub))) }
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

    context 'Press interval set to false' do
      let(:interval) { false }

      context 'OA title' do
        let(:open_access) { 'yes' }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              expect(page).not_to have_xpath(".//i[@title='Download section']")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end

      context 'not an OA title' do
        let(:open_access) { nil }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end
    end

    context 'Press interval set to true' do
      let(:interval) { true }

      context 'OA title' do
        let(:open_access) { 'yes' }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end

      context 'not an OA title' do
        let(:open_access) { nil }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end
    end
  end

  context 'page image epub' do
    let(:epub) { 'the-whale.epub' }

    context 'Press interval set to false' do
      let(:interval) { false }

      context 'OA title' do
        let(:open_access) { 'yes' }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end

      context 'not an OA title' do
        let(:open_access) { nil }

        context 'not restricted' do
          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end
    end

    context 'Press interval set to true' do
      let(:interval) { true }

      context 'OA title' do
        let(:open_access) { 'yes' }

        context 'not restricted' do
          it 'has links and buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              # expect(page).to have_xpath(".//span[@title='Read section']")
              # expect(page).to have_xpath(".//i[@title='Download section']")
              # expect(page).to have_xpath(".//a[@class='toc-download-link']")
              expect(page).to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links and buttons (buttons because OA takes precedence over restricted)' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              # expect(page).to have_xpath(".//span[@title='Read section']")
              # expect(page).to have_xpath(".//i[@title='Download section']")
              expect(page).to have_content("Download")
            end
          end
        end
      end

      context 'not an OA title' do
        let(:open_access) { nil }

        context 'not restricted' do
          it 'has links and buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              # expect(page).to have_xpath(".//span[@title='Read section']")
              # expect(page).to have_xpath(".//i[@title='Download section']")
              expect(page).to have_content("Download")
            end
          end
        end

        context 'restricted' do
          let(:parent) { Sighrax.from_noid(monograph.id) }
          before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

          it 'has links but no buttons' do
            visit monograph_catalog_path(monograph)
            click_on("Contents")
            within("#toc") do
              expect(page).to have_xpath(".//a[@class='toc-link']")
              # expect(page).not_to have_xpath(".//span[@title='Read section']")
              # expect(page).not_to have_xpath(".//i[@title='Download section']")
              expect(page).not_to have_content("Download")
            end
          end
        end
      end
    end
  end
end
