# frozen_string_literal: true

require 'rails_helper'

describe 'Press-specific display on the Monograph Catalog' do
  context 'Series labelling' do
    let(:monograph_with_series_values) { create(:public_monograph,
                                                press: press.subdomain,
                                                series: ['The Cereal Series', 'The Second Series']) }

    context 'regular, no-override press' do
      let(:press) { create(:press) }

      it 'Uses "Series" as the label' do
        visit hyrax_monograph_path(monograph_with_series_values)

        # series - uses "Series" as the label... as you'd expect!
        series_subject_div_text = find('div.subject-series').text
        expect(series_subject_div_text).to start_with('Series')
        expect(series_subject_div_text).to_not start_with('Collection')
        expect(page).to have_content 'The Cereal Series'
        expect(page).to have_content 'The Second Series'
      end
    end

    context 'bigten press' do
      let(:press) { create(:press, subdomain: 'bigten') }

      it 'Uses "Collection" as the label' do
        visit hyrax_monograph_path(monograph_with_series_values)

        # series - special label for bigten press, which uses "Collection" as the label instead of "Series"
        series_subject_div_text = find('div.subject-series').text
        expect(series_subject_div_text).to start_with('Collection')
        expect(series_subject_div_text).to_not start_with('Series')
        expect(page).to have_content 'The Cereal Series'
        expect(page).to have_content 'The Second Series'
      end
    end

    context 'livedplaces press' do
      let(:press) { create(:press, subdomain: 'livedplaces') }

      it 'Uses "Collection" as the label' do
        visit hyrax_monograph_path(monograph_with_series_values)

        # series - special label for livedplaces press, which uses "Collection" as the label instead of "Series"
        series_subject_div_text = find('div.subject-series').text
        expect(series_subject_div_text).to start_with('Collection')
        expect(series_subject_div_text).to_not start_with('Series')
        expect(page).to have_content 'The Cereal Series'
        expect(page).to have_content 'The Second Series'
      end
    end
  end
end
