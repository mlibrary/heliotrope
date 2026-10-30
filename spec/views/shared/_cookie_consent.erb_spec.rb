# frozen_string_literal: true

require 'rails_helper'
require 'execjs'

describe 'shared/_cookie_consent.erb' do
  let(:analytics) do
    instance_double(ExternalAnalyticsPresenter, press_ga4_ids: [], tag_manager_id?: false, primary_ga4_id?: false)
  end

  before do
    allow(view).to receive(:press_presenter).and_return(nil)
    allow(ExternalAnalyticsPresenter).to receive(:new).and_return(analytics)
  end

  def run_consent(actions, monitoring: true)
    render partial: 'shared/cookie_consent', locals: { monitoring: monitoring }
    scripts = Nokogiri::HTML.fragment(rendered).css('script:not([src])').map(&:text).join("\n")

    ExecJS.eval(<<~JS)
      (function() {
        var scripts = [];
        var consent = false;
        var options;
        var originalOnerror = function() {};
        var window = {
          performance: { timing: {}, navigation: {} },
          onerror: originalOnerror
        };
        var document = {
          createElement: function() {
            return { setAttribute: function(name, value) { this[name] = value; } };
          },
          getElementsByTagName: function() {
            return [{ appendChild: function(script) { scripts.push(script.src); } }];
          }
        };
        var $ = function() {
          return {
            ihavecookies: function(settings) { options = settings; },
            on: function() {},
            ready: function() {},
            trigger: function() {}
          };
        };
        $.fn = { ihavecookies: { preference: function() { return consent; } } };
        #{scripts}
        #{actions}
        return {
          scripts: scripts,
          errorHandlerInstalled: window.onerror !== originalOnerror,
          monitoringInitialized: typeof window.s247r === 'function'
        };
      })()
    JS
  end

  it 'does not initialize monitoring before consent or when analytics is declined' do
    result = run_consent('initCookieConsent(); options.onAccept();')

    expect(result).to eq('scripts' => [], 'errorHandlerInstalled' => false, 'monitoringInitialized' => false)
  end

  it 'initializes monitoring when analytics consent is granted on the current page' do
    result = run_consent('initCookieConsent(); consent = true; options.onAccept();')

    expect(result['scripts']).to contain_exactly(a_string_including('static.site24x7rum.com/beacon/site24x7rum-min.js'))
    expect(result['errorHandlerInstalled']).to be true
    expect(result['monitoringInitialized']).to be true
  end

  it 'initializes monitoring with saved analytics consent' do
    result = run_consent('consent = true; initCookieConsent();')

    expect(result['scripts'].size).to eq(1)
    expect(result['errorHandlerInstalled']).to be true
  end

  it 'does not initialize monitoring again on repeated acceptance or Turbolinks initialization' do
    result = run_consent('consent = true; initCookieConsent(); options.onAccept(); initCookieConsent();')

    expect(result['scripts'].size).to eq(1)
  end

  it 'does not include or initialize monitoring when the layout has not enabled it' do
    result = run_consent('consent = true; initCookieConsent(); options.onAccept();', monitoring: false)

    expect(rendered).not_to include('loadSite24x7Monitoring')
    expect(result).to eq('scripts' => [], 'errorHandlerInstalled' => false, 'monitoringInitialized' => false)
  end
end
