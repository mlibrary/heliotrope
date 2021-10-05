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

  context "all facets" do
    let(:monograph) { create(:public_monograph, title: ["Yellow"], representative_id: cover.id) }
    let(:file_set1) {
      create(:public_file_set, resource_type: ['image'],
                               exclusive_to_platform: 'yes',
                               creator: ["McTesterson, Testy\nCoauthorson, Timmy"],
                               sort_date: '1974-01-01',
                               keywords: ['aardvark', 'Gophers', 'stuff', 'things', 'Stuff'],
                               section_title: ['A Section'])
    }

    let(:file_set2) {
      create(:public_file_set, resource_type: ['video'],
             exclusive_to_platform: 'yes',
             creator: ['Bloggs, Joe'],
             sort_date: '1984-01-01',
             keywords: ['blah', 'stuff'],
             section_title: ['B Section'])
    }

    before do
      file_sets = [cover, file_set1, file_set2]
      monograph.ordered_members = file_sets
      monograph.save!
      file_sets.map(&:save!)
    end

    it "shows the correct facets" do
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to_not have_content("Your search has returned")

      expect(page).to have_selector('#facet-section_title_sim a.facet_select')

      expect(page).to have_selector('#facet-creator_sim a.facet_select', count: 3)
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'McTesterson, Testy')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'Coauthorson, Timmy')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'Bloggs, Joe')

      expect(page).to have_selector('#facet-resource_type_sim a.facet_select', text: 'image')
      expect(page).to have_selector('#facet-resource_type_sim a.facet_select', text: 'video')

      expect(page).to have_selector('#facet-search_year_sim a.facet_select', count: 2)
      expect(page).to have_selector('#facet-exclusive_to_platform_sim a.facet_select')

      keyword_facet_labels = page.all('#facet-keywords_sim a.facet_select .facet-label')
      expect(keyword_facet_labels.count).to eq 5 # facet limit is 5
      keyword_facet_counts = page.all('#facet-keywords_sim a.facet_select > span:nth-of-type(2)')
      expect(keyword_facet_counts.count).to eq 5 # facet limit is 5

      # default 'count' sort with fall back to case-insensitive alphabetic 'index' sort
      expect(keyword_facet_labels[0]).to have_content 'stuff'
      expect(keyword_facet_counts[0]).to have_content '2'
      expect(keyword_facet_labels[1]).to have_content 'aardvark'
      expect(keyword_facet_counts[1]).to have_content '1'
      expect(keyword_facet_labels[2]).to have_content 'blah'
      expect(keyword_facet_counts[2]).to have_content '1'
      expect(keyword_facet_labels[3]).to have_content 'Gophers' # HELIO-3111 case-insensitive sort
      expect(keyword_facet_counts[3]).to have_content '1'
      expect(keyword_facet_labels[4]).to have_content 'Stuff'
      expect(keyword_facet_counts[4]).to have_content '1'

      # somehow this expect gets the find afterwards to work more consistently, in the system specs anyway
      expect(page).to have_css("div#facet-keywords_sim a.more_facets_link")
      # click "more" link to open full-screen facet modal overlay
      find("a[href='#{monograph_catalog_facet_path(id: 'keywords_sim', monograph_id: monograph.id, locale: 'en', oa_marker: 'monograph')}']")
          .click

      keyword_facet_labels = page.all('a.facet_select .facet-label')
      expect(keyword_facet_labels.count).to eq 6
      keyword_facet_counts = page.all('a.facet_select > span:nth-of-type(2)')
      expect(keyword_facet_counts.count).to eq 6

      expect(keyword_facet_labels[0]).to have_content 'stuff'
      expect(keyword_facet_counts[0]).to have_content '2'
      expect(keyword_facet_labels[1]).to have_content 'aardvark'
      expect(keyword_facet_counts[1]).to have_content '1'
      expect(keyword_facet_labels[2]).to have_content 'blah'
      expect(keyword_facet_counts[2]).to have_content '1'
      expect(keyword_facet_labels[3]).to have_content 'Gophers' # HELIO-3111 case-insensitive sort
      expect(keyword_facet_counts[3]).to have_content '1'
      expect(keyword_facet_labels[4]).to have_content 'Stuff'
      expect(keyword_facet_counts[4]).to have_content '1'
      expect(keyword_facet_labels[5]).to have_content 'things'
      expect(keyword_facet_counts[5]).to have_content '1'

      # HELIO-3688
      expect(page).to have_css(".sort_options.btn-group.pull-right[role=tablist]")
      expect(page).to have_css("span.active.numeric.btn.btn-default[role=tab][aria-selected=true]")
      expect(page).to have_css("a.sort_change.az.btn.btn-default[href*='keywords_sim?facet.sort=index'][role=tab][aria-selected=false]")

      # change to A-Z Sort. specificity because on the actual page used for the more AJAX view there are two sets...
      # of sort buttons, with the upper ones hidden in the modal
      find('.facet_pagination.bottom .sort_options a.sort_change.az.btn.btn-default').click

      keyword_facet_labels = page.all('a.facet_select .facet-label')
      expect(keyword_facet_labels.count).to eq 6
      keyword_facet_counts = page.all('a.facet_select > span:nth-of-type(2)')
      expect(keyword_facet_counts.count).to eq 6

      expect(keyword_facet_labels[0]).to have_content 'aardvark'
      expect(keyword_facet_counts[0]).to have_content '1'
      expect(keyword_facet_labels[1]).to have_content 'blah'
      expect(keyword_facet_counts[1]).to have_content '1'
      expect(keyword_facet_labels[2]).to have_content 'Gophers' # HELIO-3111 case-insensitive sort
      expect(keyword_facet_counts[2]).to have_content '1'
      expect(keyword_facet_labels[3]).to have_content 'Stuff'
      expect(keyword_facet_counts[3]).to have_content '1'
      expect(keyword_facet_labels[4]).to have_content 'stuff'
      expect(keyword_facet_counts[4]).to have_content '2'
      expect(keyword_facet_labels[5]).to have_content 'things'
      expect(keyword_facet_counts[5]).to have_content '1'

      # HELIO-3688
      expect(page).to have_css(".sort_options.btn-group.pull-right[role=tablist]")
      expect(page).to have_css("span.active.az.btn.btn-default[role=tab][aria-selected=true]")
      expect(page).to have_css("a.sort_change.numeric.btn.btn-default[href*='keywords_sim?facet.sort=count'][role=tab][aria-selected=false]")
    end

    it "shows the results for a facet, with screen reader div" do
      visit monograph_catalog_path(id: monograph.id)
      click_link('stuff')
      expect(page).to have_selector('#documents .document', count: 2)
      expect(page).to have_content("Your search has returned 2 resources attached to Yellow")
    end
  end
end
