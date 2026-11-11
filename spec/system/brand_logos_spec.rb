# frozen_string_literal: true

require 'rails_helper'

# HELIO-5184 specifing logo sizes for different screen widths helps speed up page loads
# and ensures that the reserved space matches the actual image dimensions to
# keep Cumultive Layout Shift (CLS) low

RSpec.describe 'Static branding logos', type: :system, browser: true do
  [320, 1280].each do |width|
    context "at #{width}px wide" do
      before { page.current_window.resize_to(width, 900) }

      it 'reserves the loaded logo size before image dimensions are available' do
        %w[michigan livedplaces democraticfutures vermont].each do |subdomain|
          press = create(:press, subdomain: subdomain)
          visit press_catalog_path(press.subdomain)
          expect(page).to have_css('header img.navbar-brand-logo')

          measurements = page.evaluate_script(<<~JS)
            Array.from(document.querySelectorAll('header img.navbar-brand-logo, footer img.fulcrum')).map(function(image) {
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
            });
          JS

          expect(measurements).not_to be_empty
          measurements.each do |measurement|
            expect(measurement['loaded']).to be true
            expect(measurement['widthDifference']).to be <= 1
            expect(measurement['heightDifference']).to be <= 1
          end
        end
      end
    end
  end
end
