# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Uploaded press-banner logos', type: :system, browser: true do
  let(:press) { create(:press, subdomain: 'indiana') }

  [320, 1280].each do |width|
    context "at #{width}px wide" do
      before { page.current_window.resize_to(width, 900) }

      it 'reserves the default logo height before the image provides its dimensions' do
        visit press_catalog_path(press.subdomain)
        expect(page).to have_css('.jumbotron .logo img[width="180"][height="50"]')

        measurements = page.evaluate_script(<<~JS)
          (function() {
            var image = document.querySelector('.jumbotron .logo img');
            var loaded = image.getBoundingClientRect();
            var placeholder = image.cloneNode();
            placeholder.removeAttribute('src');
            placeholder.removeAttribute('alt');
            image.replaceWith(placeholder);
            var reserved = placeholder.getBoundingClientRect();
            placeholder.replaceWith(image);
            return {
              loaded: image.complete && image.naturalWidth > 0,
              widthDifference: Math.abs(loaded.width - reserved.width),
              heightDifference: Math.abs(loaded.height - reserved.height)
            };
          })()
        JS

        expect(measurements['loaded']).to be true
        expect(measurements['widthDifference']).to be <= 1
        expect(measurements['heightDifference']).to be <= 1
      end
    end
  end
end
