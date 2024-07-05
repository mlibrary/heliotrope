# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog PDF Download Warning Spec" do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: 'blue') }
  let(:press_analyst) { create(:press_analyst, subdomain: 'blue') }
  let(:monograph) { create(:public_monograph, press: press.subdomain, user: user, visibility: "open") }
  let(:epub) { create(:public_file_set, id: '999999999', allow_download: 'yes') }
  let!(:epub_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
  let(:pdf) { create(:public_file_set, id: '888888888', allow_download: 'yes') }
  let!(:pdf_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf.id, kind: 'pdf_ebook') }

  before do
    stub_out_redis
    monograph.ordered_members << epub
    monograph.ordered_members << pdf
    monograph.save!
    epub.save!
    pdf.save!
  end

  it "Does not show the PDF warning to anonymous users" do
    visit monograph_catalog_path(monograph, locale: 'en')

    expect(page).to have_selector('#monograph-download-btn')
    expect(page).to have_selector('a[data-rep-type=epub]')
    expect(page).to have_selector('a[data-rep-type=pdf]')
    expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
    expect(page).to_not have_selector('a[data-rep-type=pdf][data-confirm]')
  end

  it 'shows the PDF warning to press analysts' do
    login_as(create(:press_analyst, press: press))
    visit monograph_catalog_path(monograph, locale: 'en')

    expect(page).to have_selector('#monograph-download-btn')
    expect(page).to have_selector('a[data-rep-type=epub]')
    expect(page).to have_selector('a[data-rep-type=pdf]')
    # the warning does not apply to EPUBs
    expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
    expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
  end

  it 'shows the PDF warning to press editors' do
    login_as(create(:press_editor, press: press))
    visit monograph_catalog_path(monograph, locale: 'en')

    expect(page).to have_selector('#monograph-download-btn')
    expect(page).to have_selector('a[data-rep-type=epub]')
    expect(page).to have_selector('a[data-rep-type=pdf]')
    # the warning does not apply to EPUBs
    expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
    expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
  end

  it 'shows the PDF warning to press admins' do
    login_as(create(:press_admin, press: press))
    visit monograph_catalog_path(monograph, locale: 'en')

    expect(page).to have_selector('#monograph-download-btn')
    expect(page).to have_selector('a[data-rep-type=epub]')
    expect(page).to have_selector('a[data-rep-type=pdf]')
    # the warning does not apply to EPUBs
    expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
    expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
  end

  it 'shows the PDF warning to platform admins' do
    login_as(create(:platform_admin))
    visit monograph_catalog_path(monograph, locale: 'en')

    expect(page).to have_selector('#monograph-download-btn')
    expect(page).to have_selector('a[data-rep-type=epub]')
    expect(page).to have_selector('a[data-rep-type=pdf]')
    # the warning does not apply to EPUBs
    expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
    expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
  end
end
