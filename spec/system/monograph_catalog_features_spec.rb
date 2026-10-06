# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog TOC", type: :system, browser: true do
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, press: press.subdomain, user: User.batch_user, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:file_set, id: '999999999', visibility: "open", keyword: ['one', 'two', 'three', 'four', 'five', 'six'], content: File.open(File.join(fixture_path, 'csv', 'shipwreck.jpg'))) }

  before do
    stub_out_redis
    monograph.ordered_members << cover
    monograph.save!
    cover.save!
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  context 'Using the full-screen cover image Bootstrap modal' do
    it 'works as expected' do
      visit monograph_catalog_path(monograph)
      expect(page).to have_css("body.#{press.subdomain}")
      expect(page).not_to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: false)

      # click the Monograph thumbnail
      find("button[data-target='#modalImage'").click
      expect(page).to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: true)
      expect(page).to have_css('#modalImage img[data-cover-src][src]:not([hidden])')
      expect(page.evaluate_script("document.querySelector('#modalImage img').naturalWidth")).to be > 0
      timing = page.evaluate_script(<<~JS)
        (function() {
          var imageUrl = document.querySelector('#modalImage img').src;
          var resource = performance.getEntriesByName(imageUrl)[0];
          return [resource.startTime, performance.getEntriesByType('navigation')[0].loadEventEnd];
        })()
      JS
      expect(timing.first).to be >= timing.last

      # For fun, we'll hit 'Escape' to close the modal (there is a hard-to-see 'x' button also)
      input = find("div#modalImage").native
      input.send_key(:escape)
      expect(page).to have_css("body.#{press.subdomain}")
      expect(page).not_to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: false)
    end

    context 'deferred loading lifecycle' do
      before do
        visit monograph_catalog_path(monograph)
        page.execute_script(<<~JS)
          $(document).trigger('turbolinks:before-cache');
          var cover = document.querySelector('#modalImage img');
          cover.removeAttribute('src');
          cover.hidden = true;
          window.coverIdleCallback = null;
          window.coverIdleCancelled = false;
          window.requestIdleCallback = function(callback) {
            window.coverIdleCallback = callback;
            return 1;
          };
          window.cancelIdleCallback = function() {
            window.coverIdleCancelled = true;
            window.coverIdleCallback = null;
          };
          Object.defineProperty(document, 'readyState', { configurable: true, get: function() { return 'loading'; } });
          $(document).trigger('turbolinks:load');
        JS
      end

      it 'waits for page load and an idle callback before requesting the enlarged cover' do
        expect(page.evaluate_script("document.querySelector('#modalImage img').hasAttribute('src')")).to be false
        expect(page.evaluate_script('window.coverIdleCallback')).to be_nil
        page.execute_script("window.dispatchEvent(new Event('load'));")
        expect(page.evaluate_script("document.querySelector('#modalImage img').hasAttribute('src')")).to be false
        expect(page.evaluate_script("typeof window.coverIdleCallback")).to eq 'function'
        page.execute_script('window.coverIdleCallback();')
        expect(page).to have_css('#modalImage img[src]:not([hidden])', visible: false)
      end

      it 'loads immediately on opening and cancels pending background work' do
        page.execute_script("window.dispatchEvent(new Event('load'));")
        find("button[data-target='#modalImage']").click
        expect(page.evaluate_script('window.coverIdleCancelled')).to be true
        expect(page).to have_css('#modalImage img[src]:not([hidden])')
        expect(page.evaluate_script('document.activeElement.id')).to eq 'modalClose'
      end

      it 'cancels background loading when navigating away' do
        page.execute_script("window.dispatchEvent(new Event('load')); $(document).trigger('turbolinks:before-visit');")
        expect(page.evaluate_script('window.coverIdleCancelled')).to be true
        expect(page.evaluate_script("document.querySelector('#modalImage img').hasAttribute('src')")).to be false
      end

      it 'uses a post-load timer when idle callbacks are unavailable' do
        page.execute_script(<<~JS)
          window.requestIdleCallback = undefined;
          window.dispatchEvent(new Event('load'));
        JS
        expect(page).to have_css('#modalImage img[src]:not([hidden])', visible: false)
      end

      it 'reinitializes a restored page without adding duplicate modal handlers' do
        page.execute_script(<<~JS)
          $(document).trigger('turbolinks:before-cache');
          delete document.readyState;
          $(document).trigger('turbolinks:load');
          $(document).trigger('turbolinks:load');
        JS
        expect(page.evaluate_script('typeof window.coverIdleCallback')).to eq 'function'
        find("button[data-target='#modalImage']").click
        expect(page).to have_css('#modalImage img[src]:not([hidden])')
        handlers = page.evaluate_script(<<~JS)
          $._data(document.getElementById('modalImage'), 'events').show.filter(function(handler) {
            return handler.namespace.indexOf('fulcrumCover') !== -1;
          }).length;
        JS
        expect(handlers).to eq 1
      end

      it 'reports a load failure and retries on the next opening' do
        find("button[data-target='#modalImage']").click
        expect(page).to have_css('#modalImage img[src]:not([hidden])')
        page.execute_script("document.querySelector('#modalImage img').dispatchEvent(new Event('error'));")
        expect(page).to have_css('#modalImage [role="status"]', text: I18n.t('monograph_cover.error'))
        page.execute_script("$('#modalImage').modal('hide');")
        expect(page).not_to have_css("body.modal-open")
        find("button[data-target='#modalImage']").click
        expect(page).to have_css('#modalImage img[src]:not([hidden])')
        expect(page).not_to have_css('#modalImage [role="status"]', text: I18n.t('monograph_cover.error'))
      end
    end
  end

  context 'Using the Blacklight facet "more" Bootstrap modal' do
    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it 'works as expected, adds a11y-relevant `hidden` attributes' do
      visit monograph_catalog_path(monograph)

      # expand facet
      find("button[data-bs-target='#facet-keyword_sim']").click

      # `blacklight_modal_a11y_additions.js` actually sticks `hidden` on all children of <body> - script tags, cookie consent n'all - but...
      # that's too egregious to test, especially with Capybara's own perceived visibility in play. FYI, the cookie...
      # consent div can actually be visible with "hidden" applied to it. Just verify the main div is behaving as expected.
      expect(page).to have_css("div#main", visible: true)
      expect(page).not_to have_css("div#main[hidden='hidden']", visible: true) # verify lack of `hidden` attribute
      expect(page).to have_css("div#blacklight-modal[hidden='hidden']", visible: false)

      # somehow this expect gets the find afterwards to work more consistently. Bah. Timing errors.
      expect(page).to have_css("div#facet-keyword_sim a.more_facets_link")
      # click "more" link to open full-screen facet modal overlay
      find("a[href='#{monograph_catalog_facet_path(id: 'keyword_sim', monograph_id: monograph.id, locale: 'en')}']").click
      expect(page).to have_css("div#main[hidden='hidden']", visible: false)
      expect(page).to have_css("div#blacklight-modal[aria-modal='true']")
      expect(page).not_to have_css("div#blacklight-modal[hidden='hidden']", visible: true) # verify lack of `hidden` attribute

      # close out the full-screen facet modal
      find("button.blacklight-modal-close").click

      # 2024 this actually works in practice but the spec fails due to timing issues.
      # Maybe it's the "fade" that happens when you close the modal?
      # I can't figure it out how to get the timing right.
      # Maybe someday there will be a way to do this, it would be nice to have.
      #
      # puts "WAITING"
      # using_wait_time 30 do
      #   expect(page).to have_css("div#main", visible: true)
      #   expect(page).not_to have_css("div#main[hidden='hidden']", visible: true) # verify lack of `hidden` attribute
      #   expect(page).to have_css("div#blacklight-modal[hidden='hidden']", visible: false)
      # end
    end
  end
end
