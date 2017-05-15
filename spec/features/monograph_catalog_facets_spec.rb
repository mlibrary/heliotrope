# frozen_string_literal: true

require 'rails_helper'

feature "Monograph Catalog Facets" do
  before do
    stub_out_redis
  end

  let(:cover) { create(:public_file_set) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  context "keywords" do
    let(:monograph) { create(:public_monograph, title: ["Yellow"], representative_id: cover.id) }
    let(:file_set1) { create(:public_file_set, keywords: ["cat", "dog", "elephant", "lizard", "monkey", "mouse", "tiger"]) }
    before do
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "shows keywords in the intended order" do
      visit monograph_catalog_facet_path(id: 'keywords_sim', monograph_id: monograph.id)
      expect(page).to have_selector '.facet-values li:first', text: "cat"
    end
  end

  context "sections" do
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

    scenario "shows sections in intended order" do
      visit monograph_catalog_facet_path(id: 'section_title_sim', monograph_id: monograph.id)

      # facet section order should be:
      # "C 1"
      # "B 2"
      # "A 3"
      # so by order, not alphabetically or by frequency
      expect(page).to have_selector '.facet-values li:first', text: "C 1"
      expect(page).to_not have_selector '.facet-values li:first', text: "A 3"

      # TODO: Test the ordering of 'B 2' and 'A 3' facets
      expect(page).to have_selector '.facet-values li', text: "B 2"
      expect(page).to have_selector '.facet-values li', text: "A 3"
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

    scenario "shows italics (emphasis) in section facet links" do
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
    let(:cover) { create(:public_file_set) }
    let(:expected_resource_facet) { 'resource_facet' }
    let(:expected_content_facet) { 'content_facet' }
    let(:file_set) { create(:public_file_set, resource_type: [expected_resource_facet], content_type: [expected_content_facet]) }
    let(:facets) { "#facets" }
    let(:selected_facets) { "#appliedParams" }

    scenario "Select facets from resource_type (parent) and content_type (child)" do
      visit monograph_catalog_path(id: monograph.id)
      # puts page.html

      # Initially no facets selected
      expect(page).to_not have_css(selected_facets)

      # Initial both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
        expect(page).to_not have_link "[remove]"

        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to_not have_content("f[content_type_sim][]=#{expected_content_facet}")

        content_link = page.find_link(expected_content_facet)
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).to_not have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Select resource_type parent facet
        resource_link.click
      end

      # Only parent facet should be selected.
      within selected_facets do
        expect(page).to have_content "Resource type #{expected_resource_facet}", count: 1
        expect(page).to have_content "Remove constraint Resource type: #{expected_resource_facet}", count: 1
        expect(page).to have_content "Content #{expected_content_facet}", count: 0
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 0
      end

      within facets do
        expect(page).to have_link "[remove]", count: 1

        # Resource link rendered with facet_helper#render_selected_facet_pivot_value
        resource_link = page.find(:xpath, ".//a[@class='remove']")
        expect(resource_link).to have_content("[remove]")
        expect(CGI.unescape(resource_link[:href])).to_not have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to_not have_content("f[content_type_sim][]=#{expected_content_facet}")

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
        expect(page).to have_content "Resource type #{expected_resource_facet}", count: 1
        expect(page).to have_content "Remove constraint Resource type: #{expected_resource_facet}", count: 1
        expect(page).to have_content "Content #{expected_content_facet}", count: 1
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 1
      end

      # Both facets rendered with facet_helper#render_selected_facet_pivot_value
      within facets do
        expect(page).to have_link "[remove]", count: 2

        resource_link = page.find(:xpath, ".//a[@class='remove'][contains(@href,'#{expected_content_facet}')]")
        expect(resource_link).to have_content("[remove]")
        expect(CGI.unescape(resource_link[:href])).to_not have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        content_link = page.find(:xpath, ".//a[@class='remove'][contains(@href,'#{expected_resource_facet}')]")
        expect(content_link).to have_content("[remove]")
        expect(CGI.unescape(content_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to_not have_content("f[content_type_sim][]=#{expected_content_facet}")

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
        expect(page).to have_link "[remove]", count: 1

        # Resource link rendered with facet_helper#render_facet_pivot_value
        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Content link rendered with facet_helper#render_selected_facet_pivot_value
        content_link = page.find(:xpath, ".//a[@class='remove']")
        expect(content_link).to have_content("[remove]")
        expect(CGI.unescape(content_link[:href])).to_not have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to_not have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Unselect content_type child facet
        content_link.click
      end

      # Return to initial condition of no facets selected
      expect(page).to_not have_css(selected_facets)

      # Both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
        expect(page).to_not have_link "[remove]"

        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to_not have_content("f[content_type_sim][]=#{expected_content_facet}")

        content_link = page.find_link(expected_content_facet)
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).to_not have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")
      end
    end
  end

  context "all facets" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
    before do
      login_as user
      monograph.ordered_members << cover
      monograph.save!
    end

    scenario "shows the correct facets" do
      visit monograph_show_path(monograph)
      click_link 'Attach a File'
      fill_in 'Title', with: 'File Title'
      fill_in 'Resource Type', with: 'image'
      fill_in 'Content Type', with: 'portrait'
      fill_in 'Exclusive to Platform?', with: 'yes'
      fill_in 'Primary Creator (family name)', with: 'McTesterson'
      fill_in 'Primary Creator (given name)', with: 'Testy'
      fill_in 'Sort Date', with: '1974-01-01'
      fill_in 'Keywords', with: 'stuff'
      fill_in 'Related Section', with: 'A Section'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Monograph'

      # Selectors needed for assets/javascripts/ga_event_tracking.js
      # If these change, fix here then update ga_event_tracking.js
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector('#facet-section_title_sim a.facet_select')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select')
      expect(page).to have_selector('#facet-creator_full_name_sim a.facet_select')
      expect(page).to have_selector('#facet-resource_type_sim a.facet_select')
      # content type is nested/pivoted under resource type
      expect(find('#facet-resource_type_sim-image a.facet_select').text).to eq 'portrait'
      expect(page).to have_selector('#facet-search_year_sim a.facet_select')
      expect(page).to have_selector('#facet-exclusive_to_platform_sim a.facet_select')
    end
  end
end
