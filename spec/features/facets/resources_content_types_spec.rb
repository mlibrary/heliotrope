# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Resource and Content Types nested Facets", :stubborn do
  before do
    stub_out_redis
  end

  let(:facets) { "#facets" }
  let(:selected_facets) { "#appliedParams" }
  let(:cover) { create(:public_file_set) }

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
      skip <<-SKIP
This spec fails when run with all the other specs but it's fine when run alone.
I can't figure it out.
See HELIO-2302, specifically https://tools.lib.umich.edu/jira/browse/HELIO-2302?focusedCommentId=998626&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-998626
and https://tools.lib.umich.edu/jira/browse/HELIO-2302?focusedCommentId=999680&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-999680
SKIP

      visit monograph_catalog_path(id: monograph.id)
      # puts page.html

      # Initially no facets selected
      expect(page).not_to have_css(selected_facets)

      # Initial both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
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
        # resource_link.click
        # resource_link.trigger('click')
      end

      # Only parent facet should be selected.
      page.find_link(expected_resource_facet).click
      within selected_facets do
        expect(page).to have_content "Format #{expected_resource_facet}", count: 1
        expect(page).to have_content "Remove constraint Format: #{expected_resource_facet}", count: 1
        expect(page).to have_content "Content #{expected_content_facet}", count: 0
        expect(page).to have_content "Remove constraint Content: #{expected_content_facet}", count: 0
      end

      # save_and_open_page

      within facets do
        # Resource link rendered with facet_helper#render_selected_facet_pivot_value
        resource_link = page.find(:xpath, ".//a[@class='facet-anchor selected remove']")
        expect(resource_link).to have_content(expected_resource_facet)
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
        resource_link = page.find(:xpath, ".//a[@class='facet-anchor selected remove'][contains(@href,'#{expected_content_facet}')]")
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")
        expect(resource_link[:'data-ga-event-category']).to be nil
        expect(resource_link[:'data-ga-event-action']).to be nil
        expect(resource_link[:'data-ga-event-label']).to be nil
        expect(resource_link[:'data-ga-event-value']).to be nil

        content_link = page.find(:xpath, ".//a[@class='facet-anchor selected remove'][contains(@href,'#{expected_resource_facet}')]")
        expect(content_link).to have_content(expected_content_facet)
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
        # Resource link rendered with facet_helper#render_facet_pivot_value
        resource_link = page.find_link(expected_resource_facet)
        expect(resource_link).to have_content(expected_resource_facet)
        expect(CGI.unescape(resource_link[:href])).to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(resource_link[:href])).to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Content link rendered with facet_helper#render_selected_facet_pivot_value
        content_link = page.find(:xpath, ".//a[@class='facet-anchor selected remove']")
        expect(content_link).to have_content(expected_content_facet)
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[resource_type_sim][]=#{expected_resource_facet}")
        expect(CGI.unescape(content_link[:href])).not_to have_content("f[content_type_sim][]=#{expected_content_facet}")

        # Unselect content_type child facet
        content_link.click
      end

      # Return to initial condition of no facets selected
      expect(page).not_to have_css(selected_facets)

      # Both facets rendered with facet_helper#render_facet_pivot_value
      within facets do
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
end
