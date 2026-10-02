# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_monitoring.html.erb' do
  it 'renders the Site24x7 bootstrap with the application key and error capture' do
    render

    expect(rendered).to include('//static.site24x7rum.com/beacon/site24x7rum-min.js?appKey=')
    expect(rendered).to include("'s247r','3f150fa97a0b97d16b968c6e2ff4e3f4'")
    expect(rendered).to include('!w.s247r')
    expect(rendered).to include('captureException')
  end
end
