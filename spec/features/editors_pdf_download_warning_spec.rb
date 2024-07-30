# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Editors PDF Download Warning Spec" do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: 'blue') }
  let(:monograph) { create(:public_monograph, press: press.subdomain, user: user, visibility: "open") }
  let(:epub) { create(:public_file_set, allow_download: 'yes') }
  let!(:epub_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
  let(:pdf) { create(:public_file_set, allow_download: 'yes') }
  let!(:pdf_fr) { create(:featured_representative, work_id: monograph.id, file_set_id: pdf.id, kind: 'pdf_ebook') }

  before do
    stub_out_redis
    monograph.ordered_members << epub
    monograph.ordered_members << pdf
    monograph.save!
    epub.save!
    pdf.save!
  end

  describe 'anonymous users' do
    context 'Monograph catalog page' do
      it 'Does not show the PDF warning' do
        visit monograph_catalog_path(monograph, locale: 'en')

        expect(page).to have_selector('#monograph-download-btn')
        expect(page).to have_selector('a[data-rep-type=epub]')
        expect(page).to have_selector('a[data-rep-type=pdf]')
        expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
        expect(page).to_not have_selector('a[data-rep-type=pdf][data-confirm]')
      end
    end

    context 'CSB reader' do
      it 'Does not show the PDF warning' do
        visit epub_path(id: pdf.id)
        # Bit awkward but we're not looking for a DOM element. It hasn't been constructed in this no-JS spec, but...
        # this is the ID onto which `app/assets/javascript/application/csb_editor_pdf_warning.js` will latch.
        expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
      end

      context 'no PDF to download' do
        let(:pdf) { create(:public_file_set, allow_download: 'no') }

        it 'Does not show the PDF warning' do
          visit epub_path(id: pdf.id)
          expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
        end
      end
    end
  end

  describe 'press analysts' do
    before { login_as(create(:press_analyst, press: press)) }

    context 'Monograph catalog page' do
      it 'Shows the PDF warning' do
        visit monograph_catalog_path(monograph, locale: 'en')

        expect(page).to have_selector('#monograph-download-btn')
        expect(page).to have_selector('a[data-rep-type=epub]')
        expect(page).to have_selector('a[data-rep-type=pdf]')
        # the warning does not apply to EPUBs
        expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
        expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
      end
    end

    context 'CSB reader' do
      it 'Shows the PDF warning' do
        visit epub_path(id: pdf.id)
        # Bit awkward but we're not looking for a DOM element. It hasn't been constructed in this no-JS spec, but...
        # this is the ID onto which `app/assets/javascript/application/csb_editor_pdf_warning.js` will latch.
        expect(page.body).to include('id="cozy-pdf-download-warning-required')
      end

      context 'no PDF to download' do
        # EbookDownloadOperation won't allow an analyst to download this
        let(:pdf) { create(:public_file_set, allow_download: 'no') }

        it 'Does not show the PDF warning' do
          visit epub_path(id: pdf.id)
          expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
        end
      end
    end
  end

  describe 'press editors' do
    before { login_as(create(:press_editor, press: press)) }

    context 'Monograph catalog page' do
      it 'Shows the PDF warning' do
        visit monograph_catalog_path(monograph, locale: 'en')

        expect(page).to have_selector('#monograph-download-btn')
        expect(page).to have_selector('a[data-rep-type=epub]')
        expect(page).to have_selector('a[data-rep-type=pdf]')
        # the warning does not apply to EPUBs
        expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
        expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
      end
    end

    context 'CSB reader' do
      it 'Shows the PDF warning' do
        visit epub_path(id: pdf.id)
        # Bit awkward but we're not looking for a DOM element. It hasn't been constructed in this no-JS spec, but...
        # this is the ID onto which `app/assets/javascript/application/csb_editor_pdf_warning.js` will latch.
        expect(page.body).to include('id="cozy-pdf-download-warning-required')
      end

      context 'no PDF to download' do
        # EbookDownloadOperation will allow an editor to download no matter what (pending HELIO-4569). So delete the FR.
        before { FeaturedRepresentative.delete_by(file_set_id: pdf.id) }

        it 'Does not show the PDF warning' do
          visit epub_path(id: pdf.id)
          expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
        end
      end
    end
  end

  describe 'press admins' do
    before { login_as(create(:press_admin, press: press)) }

    context 'Monograph catalog page' do
      it 'Shows the PDF warning' do
        visit monograph_catalog_path(monograph, locale: 'en')

        expect(page).to have_selector('#monograph-download-btn')
        expect(page).to have_selector('a[data-rep-type=epub]')
        expect(page).to have_selector('a[data-rep-type=pdf]')
        # the warning does not apply to EPUBs
        expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
        expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
      end
    end

    context 'CSB reader' do
      it 'Shows the PDF warning' do
        visit epub_path(id: pdf.id)
        # Bit awkward but we're not looking for a DOM element. It hasn't been constructed in this no-JS spec, but...
        # this is the ID onto which `app/assets/javascript/application/csb_editor_pdf_warning.js` will latch.
        expect(page.body).to include('id="cozy-pdf-download-warning-required')
      end

      context 'no PDF to download' do
        # EbookDownloadOperation will allow an editor to download no matter what (pending HELIO-4569). So delete the FR.
        before { FeaturedRepresentative.delete_by(file_set_id: pdf.id) }

        it 'Does not show the PDF warning' do
          visit epub_path(id: pdf.id)
          expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
        end
      end
    end
  end

  describe 'platform admins' do
    before { login_as(create(:platform_admin)) }

    context 'Monograph catalog page' do
      it 'Shows the PDF warning' do
        visit monograph_catalog_path(monograph, locale: 'en')

        expect(page).to have_selector('#monograph-download-btn')
        expect(page).to have_selector('a[data-rep-type=epub]')
        expect(page).to have_selector('a[data-rep-type=pdf]')
        # the warning does not apply to EPUBs
        expect(page).to_not have_selector('a[data-rep-type=epub][data-confirm]')
        expect(page).to have_selector('a[data-rep-type=pdf][data-confirm]')
      end
    end

    context 'CSB reader' do
      it 'Shows the PDF warning' do
        visit epub_path(id: pdf.id)
        # Bit awkward but we're not looking for a DOM element. It hasn't been constructed in this no-JS spec, but...
        # this is the ID onto which `app/assets/javascript/application/csb_editor_pdf_warning.js` will latch.
        expect(page.body).to include('id="cozy-pdf-download-warning-required')
      end

      context 'no PDF to download' do
        # EbookDownloadOperation will allow an editor to download no matter what (pending HELIO-4569). So delete the FR.
        before { FeaturedRepresentative.delete_by(file_set_id: pdf.id) }

        it 'Does not show the PDF warning' do
          visit epub_path(id: pdf.id)
          expect(page.body).to_not include('id="cozy-pdf-download-warning-required')
        end
      end
    end
  end
end
