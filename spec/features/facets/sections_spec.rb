# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Sections Facets", type: :feature do
  before do
    stub_out_redis
    stub_out_irus
  end

  let(:cover) { create(:public_file_set) }

  context "sections using fileset section_title (fallback) for order" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      file_sets = [cover, fs1, fs2, fs3, fs4, fs5, fs6]
      m.ordered_members = file_sets
      m.save!
      file_sets.map(&:save!)
      m
    end

    # Section 1 has 1 file
    let(:s1_title) { ['C 1'] }
    let(:fs1) { build(:public_file_set, title: ['Sec 1 File 1'], section_title: s1_title) }

    # Section 2 has 2 files
    let(:s2_title) { ['B 2'] }
    let(:fs2) { build(:public_file_set, title: ['Sec 2 File 1'], section_title: s2_title) }
    let(:fs3) { build(:public_file_set, title: ['Sec 2 File 2'], section_title: s2_title) }

    # Section 3 has 3 files
    let(:s3_title) { ['A 3'] }
    let(:fs4) { build(:public_file_set, title: ['Sec 3 File 1'], section_title: s3_title) }
    let(:fs5) { build(:public_file_set, title: ['Sec 3 File 2'], section_title: s3_title) }
    let(:fs6) { build(:public_file_set, title: ['Sec 3 File 3'], section_title: s3_title) }

    it "shows sections in intended order" do
      visit monograph_catalog_facet_path(id: 'section_title_sim', monograph_id: monograph.id)

      # facet section order should be:
      # "C 1"
      # "B 2"
      # "A 3"
      # so by order, not alphabetically or by frequency
      expect(page).to have_selector '.facet-values li:first', text: "C 1"
      expect(page).not_to have_selector '.facet-values li:first', text: "A 3"

      expect(page).to have_selector '.facet-values li', text: "B 2"
      expect(page).to have_selector '.facet-values li', text: "A 3"
      expect(page.body).to match(/C 1.*B 2.*A 3/)
    end
  end

  context "sections using monograph section_titles for order" do
    let(:monograph) do
      m = build(:public_monograph,
                title: ["Yellow"],
                representative_id: cover.id,
                # intended
                section_titles: "C 1\nB 2\nA 3")
      file_sets = [cover, fs1, fs2, fs3, fs4, fs5, fs6]
      m.ordered_members = file_sets
      m.save!
      file_sets.map(&:save!)
      m
    end

    # first fileset has multiple sections, third section 'A3' can potentially show up first...
    # when calculating section order from FileSets' section_titles alone
    let(:fs1) { build(:public_file_set, title: ['File 1'], section_title: ['A 3', 'C 1']) }
    let(:fs2) { build(:public_file_set, title: ['File 2'], section_title: ['B 2']) }
    # more out-of-order section madness here
    let(:fs3) { build(:public_file_set, title: ['File 3'], section_title: ['B 2', 'A 3']) }
    let(:fs4) { build(:public_file_set, title: ['File 4'], section_title: ['C 1']) }
    let(:fs5) { build(:public_file_set, title: ['File 5'], section_title: ['B 2']) }
    let(:fs6) { build(:public_file_set, title: ['File 6'], section_title: ['A 3']) }

    it "shows sections in intended order" do
      visit monograph_catalog_facet_path(id: 'section_title_sim', monograph_id: monograph.id)

      # facet section order should be enforced by the monograph's section_titles
      expect(page).to have_selector '.facet-values li:first', text: "C 1"
      expect(page).not_to have_selector '.facet-values li:first', text: "A 3"
      expect(page.body).to match(/C 1.*B 2.*A 3/)
      expect(page.body).not_to match(/A 3.*B 2.*C 1/)
    end
  end

  context "with italics in the title" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      file_sets = [cover, fs]
      m.ordered_members = file_sets
      m.save!
      file_sets.map(&:save!)
      m
    end

    let(:fs) { create(:public_file_set, section_title: ["A Section with _Italicized Title_ Stuff"]) }

    it "shows italics (emphasis) in section facet links" do
      visit monograph_catalog_path(id: monograph.id)
      # get text inside <em> tags
      italicized_text = page.first('#facet-section_title_sim li .facet_select em').text
      expect(italicized_text).to eq 'Italicized Title'

      # the facet breadcrumb does not show the markdown underscores
      click_link 'A Section with Italicized Title Stuff'
      facet_breadcrumb_text = page.first('.appliedFilter span .filterValue').text
      expect(facet_breadcrumb_text).to eq 'A Section with Italicized Title Stuff'
    end
  end
end
