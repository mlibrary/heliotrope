# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Facets" do
  before do
    stub_out_redis
  end

  let(:facets) { "#facets" }
  let(:selected_facets) { "#appliedParams" }
  let(:cover) { create(:public_file_set) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  context "keywords" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      m.ordered_members = [cover, file_set]
      m.save!
      m
    end
    let(:file_set) { create(:public_file_set, keywords: %w[cat dog elephant lizard monkey mouse tiger]) }

    it "shows keywords in the intended order" do
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector 'ul.facet-values li:nth-child(1)', text: 'cat'
      expect(page).to have_selector 'ul.facet-values li:nth-child(2)', text: 'dog'
      expect(page).to have_selector 'ul.facet-values li:nth-child(3)', text: 'elephant'
      expect(page).to have_selector 'ul.facet-values li:nth-child(4)', text: 'lizard'
      expect(page).to have_selector 'ul.facet-values li:nth-child(5)', text: 'monkey'
      expect(page).to have_selector 'ul.facet-values li:nth-child(6)', text: 'more'

      # Initially no facets selected
      expect(page).not_to have_css(selected_facets)
      # Facets rendered with facet_helper#render_facet_value

      within facets do
        cat_link = page.find_link('cat')
        expect(cat_link).to have_content('cat')
        expect(CGI.unescape(cat_link[:href])).to have_content("f[keywords_sim][]=cat")
        expect(cat_link[:'data-ga-event-category']).to be nil
        expect(cat_link[:'data-ga-event-action']).to eq("facet_keyword")
        expect(cat_link[:'data-ga-event-label']).to eq('cat')
        expect(cat_link[:'data-ga-event-value']).to be nil
        cat_link.click
      end

      # Cat facet selected
      expect(page).to have_css(selected_facets)
      # Cat facet rendered with facet_helper#render_selected_facet_value

      within facets do
        cat_link = page.find_link('cat')
        expect(cat_link).to have_content('cat')
        expect(CGI.unescape(cat_link[:href])).not_to have_content("f[keywords_sim][]=cat")
        expect(cat_link[:'data-ga-event-category']).to be nil
        expect(cat_link[:'data-ga-event-action']).to be nil
        expect(cat_link[:'data-ga-event-label']).to be nil
        expect(cat_link[:'data-ga-event-value']).to be nil
      end
    end
  end

  context "sections using fileset section_title (fallback) for order" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      m.ordered_members = [cover, fs1, fs2, fs3, fs4, fs5, fs6]
      m.save!
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
      m.ordered_members = [cover, fs1, fs2, fs3, fs4, fs5, fs6]
      m.save!
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
      m.ordered_members = [cover, fs]
      m.save!
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

  context "resource_type facet has content_type pivot facet" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Monograph Title"], representative_id: cover.id)
      m.ordered_members = [cover, file_set]
      m.save!
      m
    end
    # let(:cover) { create(:public_file_set) }
    let(:expected_resource_facet) { 'resource_facet' }
    let(:expected_content_facet) { 'content_facet' }
    let(:file_set) { create(:public_file_set, resource_type: [expected_resource_facet], content_type: [expected_content_facet]) }

    it "Select facets from resource_type (parent) and content_type (child)" do
      visit monograph_catalog_path(id: monograph.id)
      # puts page.html

      # Initially no facets selected
      expect(page).not_to have_css(selected_facets)

      # Initial both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
        expect(page).not_to have_link "Remove"

        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")
        expect(resource_link[:'data-ga-event-category']).to be nil
        expect(resource_link[:'data-ga-event-action']).to eq("facet_format")
        expect(resource_link[:'data-ga-event-label']).to eq(expected_resource_facet)
        expect(resource_link[:'data-ga-event-value']).to be nil

        content_link = page.find_link(expected_content_facet)
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")
        expect(content_link[:'data-ga-event-category']).to be nil
        expect(content_link[:'data-ga-event-action']).to eq("facet_format_content")
        expect(content_link[:'data-ga-event-label']).to eq(expected_resource_facet + '_' + expected_content_facet)
        expect(content_link[:'data-ga-event-value']).to be nil

        # Select resource_type parent facet
        resource_link.click
      end

      # Only parent facet should be selected.
      within selected_facets do
        expect(page).to have_content "Format #{expected_resource_facet}", count: 1
        expect(page).to have_content "Remove constraint Format: #{expected_resource_facet}", count: 1
        expect(page).to have_content "Content #{expected_content_facet}", count: 0
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 0
      end

      within facets do
        # save_and_open_page
        expect(page).to have_link "Remove", count: 1

        # Resource link rendered with facet_helper#render_selected_facet_pivot_value
        resource_link = page.find(:xpath, ".//a[@class='selected remove']")
        expect(resource_link).to have_content("Remove")
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Content link rendered with facet_helper#render_facet_pivot_value
        content_link = page.find_link(expected_content_facet)
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Select content_type child facet
        content_link.click
      end

      # Now both parent and child facet should be selected.
      # Verify the parent facet appears in the list only 1 time.
      within selected_facets do
        expect(page).to have_content "Format #{expected_resource_facet}", count: 1
        expect(page).to have_content "Remove constraint Format: #{expected_resource_facet}", count: 1
        expect(page).to have_content "Content #{expected_content_facet}", count: 1
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 1
      end

      # Both facets rendered with facet_helper#render_selected_facet_pivot_value
      within facets do
        expect(page).to have_link "Remove", count: 2

        resource_link = page.find(:xpath, ".//a[@class='selected remove'][contains(@href,'#{expected_content_facet}')]")
        expect(resource_link).to have_content("Remove")
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")
        expect(resource_link[:'data-ga-event-category']).to be nil
        expect(resource_link[:'data-ga-event-action']).to be nil
        expect(resource_link[:'data-ga-event-label']).to be nil
        expect(resource_link[:'data-ga-event-value']).to be nil

        content_link = page.find(:xpath, ".//a[@class='selected remove'][contains(@href,'#{expected_resource_facet}')]")
        expect(content_link).to have_content("Remove")
        expect(CGI.unescape(content_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")
        expect(content_link[:'data-ga-event-category']).to be nil
        expect(content_link[:'data-ga-event-action']).to be nil
        expect(content_link[:'data-ga-event-label']).to be nil
        expect(content_link[:'data-ga-event-value']).to be nil

        # Unselect resource_type parent facet
        resource_link.click
      end

      # Only child should be selected
      within selected_facets do
        expect(page).to have_content "Format #{expected_resource_facet}", count: 0
        expect(page).to have_content "Remove constraint Format: #{expected_resource_facet}", count: 0
        expect(page).to have_content "Content #{expected_content_facet}", count: 1
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 1
      end

      within facets do
        expect(page).to have_link "Remove", count: 1

        # Resource link rendered with facet_helper#render_facet_pivot_value
        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Content link rendered with facet_helper#render_selected_facet_pivot_value
        content_link = page.find(:xpath, ".//a[@class='selected remove']")
        expect(content_link).to have_content("Remove")
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Unselect content_type child facet
        content_link.click
      end

      # Return to initial condition of no facets selected
      expect(page).not_to have_css(selected_facets)

      # Both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
        expect(page).not_to have_link "Remove"

        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")

        content_link = page.find_link(expected_content_facet)
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")
      end
    end
  end

  context "all facets" do
    let(:monograph) { create(:public_monograph, title: ["Yellow"], representative_id: cover.id) }
    let(:file_set) {
      create(:public_file_set, resource_type: ['image'],
                               content_type: ['portrait'],
                               exclusive_to_platform: 'yes',
                               creator: ["McTesterson, Testy\nCoauthorson, Timmy"],
                               sort_date: '1974-01-01',
                               keywords: ['stuff', 'things'],
                               section_title: ['A Section'])
    }

    before do
      monograph.ordered_members = [cover, file_set]
      monograph.save!
    end

    it "shows the correct facets" do
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector('#facet-section_title_sim a.facet_select')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', count: 2)
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', text: 'stuff')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', text: 'things')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', count: 2)
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'McTesterson, Testy')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'Coauthorson, Timmy')
      expect(page).to have_selector('#facet-resource_type_sim a.facet_select')

      # content type is nested/pivoted under resource type
      expect(find('#facet-resource_type_sim-image a.facet_select').text).to eq 'Add filter Content: portrait to constrain results to 1 item'
      expect(page).to have_selector('#facet-search_year_sim a.facet_select')
      expect(page).to have_selector('#facet-exclusive_to_platform_sim a.facet_select')
    end
  end
end
