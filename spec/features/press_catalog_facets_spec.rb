# frozen_string_literal: true

require 'rails_helper'

describe "Press Catalog Facets" do
  describe 'Access facet' do
    let(:press) { create(:press) }

    it 'DOES NOT display the user access facet' do
      FactoryBot.create_list :public_monograph, 10, press: press.subdomain, creator: ['creator']
      visit press_catalog_path(press: press.subdomain)
      # save_and_open_page
      expect(page).to have_selector('#facet-open_access_sim')
      expect(page).to have_text 'All content'
      expect(page).to have_text 'Only content I can access'
      expect(page).not_to have_text 'Only open access content'
    end

    it 'DOES display the user access facet' do
      FactoryBot.create_list :public_monograph, 10, press: press.subdomain, creator: ['creator'], open_access: 'yes'
      visit press_catalog_path(press: press.subdomain)
      # save_and_open_page
      expect(page).to have_selector('#facet-open_access_sim')
      expect(page).to have_text 'All content'
      expect(page).to have_text 'Only content I can access'
      expect(page).to have_text 'Only open access content'
    end
  end

  describe "Source facet" do
    context "in michigan press" do
      let(:michigan_press) { create(:press, subdomain: 'michigan', name: 'University of Michigan Press') }
      let(:michigan_child_press_1) { create(:press, parent: michigan_press) }
      let(:michigan_child_press_2) { create(:press, parent: michigan_press) }

      before do
        FactoryBot.create_list :public_monograph, 5, press: michigan_press.subdomain
        FactoryBot.create_list :public_monograph, 5, press: michigan_child_press_1.subdomain
        FactoryBot.create_list :public_monograph, 5, press: michigan_child_press_2.subdomain
      end

      it "shows a 'Source' facet link for each subpress monograph (with expected counts), but not for michigan monograph" do
        visit press_catalog_path(press: michigan_press.subdomain)
        expect(page).to have_selector('#facet-press_name_sim a.facet-select', count: 2) # one entry per sub-press
        expect(page).to_not have_selector 'ul.facet-values li span.facet-label', text: michigan_press.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span.facet-label', text: michigan_child_press_1.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
        expect(page).to have_selector 'ul.facet-values li:nth-child(2) span.facet-label', text: michigan_child_press_2.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
      end
    end

    context "in mps press" do
      let(:mps_press) { create(:press, subdomain: 'mps', name: 'Michigan Publishing Services') }
      let(:mps_child_press_1) { create(:press, name: "Child_1", parent: mps_press) }
      let(:mps_child_press_2) { create(:press, name: "Child_2", parent: mps_press) }

      before do
        FactoryBot.create_list :public_monograph, 5, press: mps_press.subdomain
        FactoryBot.create_list :public_monograph, 5, press: mps_child_press_1.subdomain
        FactoryBot.create_list :public_monograph, 5, press: mps_child_press_2.subdomain
      end

      it "shows a 'Source' facet link for each subpress monograph (with expected counts), but not for mps monograph" do
        visit press_catalog_path(press: mps_press.subdomain)
        expect(page).to have_selector('#facet-press_name_sim a.facet-select', count: 2) # one entry per sub-press
        expect(page).to_not have_selector 'ul.facet-values li span.facet-label', text: mps_press.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span.facet-label', text: mps_child_press_1.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
        expect(page).to have_selector 'ul.facet-values li:nth-child(2) span.facet-label', text: mps_child_press_2.name
        expect(page).to have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
      end
    end

    context "not in michigan or mps press" do
      let(:not_michigan_press) { create(:press, subdomain: 'notmichiganormps', name: 'University of Not Michigan Press') }
      let(:not_michigan_child_press_1) { create(:press, parent: not_michigan_press) }
      let(:not_michigan_child_press_2) { create(:press, parent: not_michigan_press) }

      before do
        FactoryBot.create_list :public_monograph, 5, press: not_michigan_press.subdomain
        FactoryBot.create_list :public_monograph, 5, press: not_michigan_child_press_1.subdomain
        FactoryBot.create_list :public_monograph, 5, press: not_michigan_child_press_2.subdomain
      end

      it "does not show the 'Source' facet for each sub-press monograph, or the parent press monographs" do
        visit press_catalog_path(press: not_michigan_press.subdomain)
        expect(page).to_not have_selector('#facet-press_name_sim a.facet-select', count: 2) # one entry per sub-press
        expect(page).to_not have_selector 'ul.facet-values li span.facet-label', text: not_michigan_press.name
        expect(page).to_not have_selector 'ul.facet-values li:nth-child(1) span.facet-label', text: not_michigan_child_press_1.name
        expect(page).to_not have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
        expect(page).to_not have_selector 'ul.facet-values li:nth-child(2) span.facet-label', text: not_michigan_child_press_2.name
        expect(page).to_not have_selector 'ul.facet-values li:nth-child(1) span:nth-child(2)', text: 5 # 5 monographs
      end
    end
  end
end
