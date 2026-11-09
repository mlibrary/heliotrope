# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookSearchHitsController, type: :controller do
  let(:press) { create(:press, subdomain: 'barpublishing') }
  let(:monograph) { create(:public_monograph, press: press.subdomain) }
  let(:file_set) { create(:public_file_set) }

  before do
    allow(Flipflop).to receive(:search_snippets?).and_return(true)
    monograph.ordered_members << file_set
    monograph.save!
    file_set.save!
    create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'pdf_ebook')
    4.times do |index|
      ActiveFedora::SolrService.add(
        id: "#{file_set.id}_#{index + 1}",
        has_model_ssim: ['PdfPage'],
        file_set_id_ssi: file_set.id,
        monograph_id_ssi: monograph.id,
        page_number_isi: index + 1,
        page_content_tesiv: "A stone wall on page #{index + 1}. <script>alert('stone')</script>"
      )
    end
    ActiveFedora::SolrService.add(
      id: 'other_pdf_1', has_model_ssim: ['PdfPage'], file_set_id_ssi: '999999999',
      page_number_isi: 1, page_content_tesiv: 'Unrelated stone'
    )
    ActiveFedora::SolrService.commit
  end

  it 'returns up to three highlighted samples only from the requested book' do
    get :hits, params: { q: 'stone', file_set_id: file_set.id }
    expect(response).to have_http_status(:ok)
    snippets = JSON.parse(response.body)['snippets']
    expect(snippets.length).to eq 3
    expect(snippets.map { |sample| sample['page_number'] }).to all(be_between(1, 4))
    expect(snippets.map { |sample| sample['highlight'] }).to all(include('<mark>stone</mark>'))
    expect(snippets.map { |sample| sample['highlight'] }.join).not_to include('<script>', 'Unrelated')
  end

  it 'returns no samples for a metadata-only match' do
    get :hits, params: { q: 'unmatched', file_set_id: file_set.id }
    expect(JSON.parse(response.body)).to eq('snippets' => [])
  end

  it 'handles queries containing URL delimiters and quotes' do
    get :hits, params: { q: '"stone" & wall', file_set_id: file_set.id }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['snippets']).not_to be_empty
  end

  it 'allows short previews of published restricted books' do
    component = create(:component, noid: monograph.id)
    component.products << create(:product)
    get :hits, params: { q: 'stone', file_set_id: file_set.id }
    expect(JSON.parse(response.body)['snippets'].length).to eq 3
  end

  it 'does not expose draft books' do
    monograph.visibility = 'restricted'
    monograph.save!
    ActiveFedora::SolrService.commit
    get :hits, params: { q: 'stone', file_set_id: file_set.id }
    expect(response).to have_http_status(:not_found)
  end

  it 'does not expose previews for other presses' do
    another_press = create(:press, subdomain: 'anotherpress')
    monograph.press = another_press.subdomain
    monograph.save!
    ActiveFedora::SolrService.commit
    get :hits, params: { q: 'stone', file_set_id: file_set.id }
    expect(response).to have_http_status(:not_found)
  end

  it 'rejects invalid IDs and missing queries' do
    get :hits, params: { q: 'stone', file_set_id: 'bad OR *:*' }
    expect(response).to have_http_status(:not_found)
    get :hits, params: { file_set_id: file_set.id }
    expect(response).to have_http_status(:bad_request)
  end

  it 'returns not found when the feature is disabled' do
    allow(Flipflop).to receive(:search_snippets?).and_return(false)
    get :hits, params: { q: 'stone', file_set_id: file_set.id }
    expect(response).to have_http_status(:not_found)
  end
end
