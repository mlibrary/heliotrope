# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Press font loading', type: :system, browser: true do
  let(:michigan) { create(:press, subdomain: 'michigan', typekit: 'hfw0vui') }
  let(:indiana) { create(:press, subdomain: 'indiana') }

  def take_failed_screenshot
    false
  end

  it 'removes remote font imports from the delivered application stylesheet' do
    visit press_catalog_path(michigan.subdomain)

    stylesheet = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const stylesheet = document.querySelector('link[href*="/assets/application"]');
      fetch(stylesheet.href).then(response => response.text()).then(done);
    JS

    expect(stylesheet).to include('font-family')
    expect(stylesheet).not_to match(/@import[^;]*(?:typekit\.net|fonts\.googleapis\.com|fonts\.iu\.edu)/)
  end

  it 'preserves same-press Turbolinks visits but reloads when the font set changes' do
    visit press_catalog_path(michigan.subdomain)
    same_press_path = press_catalog_path(michigan.subdomain, q: 'font-navigation')
    other_press_path = press_catalog_path(indiana.subdomain)

    page.execute_script(<<~JS)
      window.fontNavigationToken = 'same-document';
      Turbolinks.visit(#{same_press_path.to_json});
    JS
    expect(page).to have_current_path(same_press_path)
    expect(page.evaluate_script('window.fontNavigationToken')).to eq('same-document')

    page.execute_script("Turbolinks.visit(#{other_press_path.to_json});")
    expect(page).to have_current_path(other_press_path)
    expect(page).to have_css('body.indiana')
    expect(page.evaluate_script('window.fontNavigationToken')).to be_nil
    expect(page).to have_css('head link[href^="https://fonts.iu.edu/"]', count: 1, visible: false)
    expect(page).not_to have_css('head link[href^="https://use.typekit.net/"]', visible: false)
  end
end
