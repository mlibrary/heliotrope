require 'rails_helper'

feature 'Monograph catalog sort' do
  context 'FileSet results set' do
    let(:user) { create(:platform_admin) }
    let(:cover) { create(:file_set, title: ['Representative']) }
    # this fileset_outlier will have year/format values 'above' the others
    # note: search_year is stored as a string, but possibly shouldn't be
    let(:fileset_outlier) { create(:file_set, title: ['Outlier'], search_year: '2000', resource_type: ['video']) }
    let(:monograph) { create(:monograph, user: user, title: ['Polka Dots'], representative_id: cover.id) }
    let(:per_page) { 2 }
    let(:fileset_count) { per_page + 1 } # ensure pagination
    let(:down_arrow) { "\u25BC" }
    let(:up_arrow) { "\u25B2" }

    before do
      stub_out_redis
      login_as user
      monograph.ordered_members << cover
      monograph.ordered_members << fileset_outlier
      # search_year here increments from 1900 thanks to the factory sequence
      fileset_count.times { monograph.ordered_members << FactoryGirl.create(:file_set) }
      # save the monograph first so the filesets can pull their order therein
      monograph.save!
      monograph.ordered_members.to_a.each(&:save!)
      # Stub the pagination to a low number so that we don't
      # have to create so many records to exercise pagination.
      allow_any_instance_of(::Blacklight::Configuration).to receive(:default_per_page).and_return(per_page)
    end

    scenario 'displays paginated results and is ordered as expected' do
      visit monograph_catalog_path(id: monograph.id)
      # we expect to have per_page number of results on the page
      expect(page).to have_selector('#documents .document', count: per_page)

      # should be monograph order using monograph_position_isi
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # ordered_members go from 0 to fileset_count + 1
      expect(first_fileset_link_text).to eq fileset_outlier.title.first

      # this control is styled as a drop-down but is actually a button & list, hence click_link not select
      click_link "Section #{down_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # note that monograph.ordered_members.to_a[0] is the representative file, not shown on this page.
      # descending, so last is shown first
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[fileset_count + 1].title.first

      click_link "Section #{up_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # ascending, first is shown first
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Format #{down_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # highest resource_type is the fileset_outlier, second ordered member, set to 'video' above
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Format #{up_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # lowest resource_type is the 3rd ordered member (first using the audio sequence, should be set to 'audio0001')
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[2].title.first

      click_link "Year #{down_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # highest year is the fileset_outlier, second ordered member [0, 1,... ], manually set to '2000' above
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Year #{up_arrow}"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # lowest year is the third ordered member, the first to use the factory's sequence and set to '1900'
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[2].title.first
    end
  end
end
