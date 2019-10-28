# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_brand_press_jumbotron.html.erb' do
  context 'when a press has an Analytics URL' do
    let(:press) { create(:press, subdomain: 'na', name: 'No Agenda Press', google_analytics_url: 'https://www.example.com') }
    it 'renders link to statistics page' do
      assign(:press, press)
      render
      expect(rendered).to have_link('Publisher Statistics', href: press_statistics_path(press))
    end
  end

  context 'when a press has a readership map URL' do
    let(:press) { create(:press, subdomain: 'na', name: 'No Agenda Press', readership_map_url: 'https://www.example.com') }
    it 'renders link to statistics page' do
      assign(:press, press)
      render
      expect(rendered).to have_link('Publisher Statistics', href: press_statistics_path(press))
    end
  end

  context 'when a press has neither Analytics nor readership map URLs' do
    let(:press) { create(:press, subdomain: 'na', name: 'No Agenda Press') }
    it 'suppresses link to statistics page' do
      assign(:press, press)
      render
      expect(rendered).not_to have_link('Publisher Statistics', href: press_statistics_path(press))
    end
  end
end
