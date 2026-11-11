# frozen_string_literal: true

require 'rails_helper'

# HELIO-5184 see also system/brand_logos_spec.rb
# We're reserving space for logos to keep Cumulative Layout Shift (CLS) low

describe 'Static branding logos', type: :view do
  let(:subdomain) { 'michigan' }
  let(:press) { build_stubbed(:press, subdomain: subdomain) }
  let(:presenter) { instance_double(PressPresenter, subdomain: subdomain, press: press, url: '/publisher', name: 'Publisher', navigation_block: nil) }

  before do
    allow(view).to receive(:press_presenter).and_return(presenter)
    allow(view).to receive(:current_user).and_return(nil)
    view.define_singleton_method(:show_site_search?) { false }
    stub_template 'shared/_brand_site_search.html.erb' => '', 'shared/_site_search.html.erb' => '',
                  'shared/_brand_press_footer_block_a.html.erb' => '', 'shared/_brand_press_footer_block_b.html.erb' => '',
                  'shared/_brand_press_footer_block_c.html.erb' => ''
  end

  shared_examples 'reserved logo dimensions' do
    it 'reserves space with numeric dimensions and an automatic sizing axis' do
      render partial: partial

      logos = Nokogiri::HTML.fragment(rendered).css('img')
      expect(logos).not_to be_empty
      logos.each do |logo|
        expect(logo['width']).to match(/\A[1-9]\d*\z/)
        expect(logo['height']).to match(/\A[1-9]\d*\z/)
        expect(logo['class']).to match(/logo-fixed-(height|width)/)
      end
    end
  end

  context 'custom press headers' do
    let(:partial) { 'shared/brand_press_bar_custom' }

    %w[heb michigan bigten livedplaces democraticfutures aberdeenunipress westminster boydellandbrewer newprairiepress
       leverpress amherst barpublishing mps michelt bridwell vermont msupress].each do |press_subdomain|
      context press_subdomain do
        let(:subdomain) { press_subdomain }

        include_examples 'reserved logo dimensions'
      end
    end
  end

  context 'shared Fulcrum header' do
    let(:partial) { 'shared/brand_bar' }

    include_examples 'reserved logo dimensions'
  end

  context 'shared Fulcrum footer' do
    let(:partial) { 'shared/brand_press_footer_custom' }

    %w[michigan bridwell].each do |press_subdomain|
      context press_subdomain do
        let(:subdomain) { press_subdomain }

        include_examples 'reserved logo dimensions'
      end
    end
  end
end
