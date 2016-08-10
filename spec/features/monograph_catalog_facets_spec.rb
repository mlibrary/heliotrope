require 'rails_helper'

feature "Monograph Catalog Facets" do
  let(:user) { create(:platform_admin) }
  let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
  let(:cover) { create(:file_set) }
  let(:file_set) { create(:file_set, keywords: ["cat", "dog", "elephant", "lizard", "monkey", "mouse", "tiger"]) }

  before do
    monograph.ordered_members << cover
    monograph.ordered_members << file_set
    monograph.save!
    login_as user
    stub_out_redis
  end

  it "shows the facets" do
    visit monograph_catalog_facet_path(id: 'keywords_sim', monograph_id: monograph.id)
    expect(page).to have_selector '.facet-values li:first', text: "cat"
  end
end
