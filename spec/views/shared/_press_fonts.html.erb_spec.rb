# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_press_fonts.html.erb' do
  it 'renders tracked font links for all media' do
    assign(:press, create(:press, subdomain: 'indiana'))
    render

    expect(rendered).to have_css(
      'link[rel="stylesheet"][media="all"][data-turbolinks-track="reload"]' \
      '[href="https://fonts.iu.edu/style.css?family=BentonSans:regular,bold|GeorgiaPro:regular"]',
      count: 1, visible: false
    )
    expect(rendered).not_to match(/use\.typekit\.net|fonts\.googleapis\.com/)
  end

  it 'includes the reader dependency when requested' do
    render partial: 'shared/press_fonts', locals: { reader: true }

    expect(rendered).to have_css(
      'link[data-turbolinks-track="reload"]' \
      '[href="https://fonts.googleapis.com/css?family=Open+Sans:300,400,400i,600,600i,700"]',
      count: 1, visible: false
    )
  end
end
