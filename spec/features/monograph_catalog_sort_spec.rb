require 'rails_helper'

feature 'Monograph catalog sort' do
  context 'FileSet results set' do
    let(:user) { create(:platform_admin) }
    let(:cover) { create(:file_set, title: ['Representative'], date_uploaded: DateTime.new(2000, 2, 3, 4, 1, 0, '+0')) }
    # this fileset_outlier will have year/format values 'above' the others
    # note1: setting the date_uploaded is necessary for the default sort behavior to work (done in factory)
    # note2: search_year is stored as a string, but possibly shouldn't be
    let(:fileset_outlier) { create(:file_set, title: ['Outlier'], search_year: '2000', resource_type: ['video'], date_uploaded: DateTime.new(2001, 2, 3, 4, 1, 0, '+0')) }
    let(:monograph) { create(:monograph, user: user, title: ['Polka Dots'], representative_id: cover.id) }
    let(:fileset_count) { 24 }

    before do
      stub_out_redis
      login_as user
      monograph.ordered_members << cover
      monograph.ordered_members << fileset_outlier
      # start_years here increment from 1900 thanks to the factory sequence
      fileset_count.times do |i|
        monograph.ordered_members << FactoryGirl.create(:file_set, date_uploaded: DateTime.new(2010, 2, 3, 4, i, 0, '+0'))
      end
      monograph.save!
    end

    # for reference "\u25BC" is desc (down arrow), "\u25B2" is asc (up arrow)
    scenario 'displays 20 results by default and is ordered as expected' do
      visit monograph_catalog_path(id: monograph.id)
      # 20 results on page by default
      expect(page).to have_selector('#documents .document', count: 20)

      # relevance/score with date_uploaded desc (date_uploaded is also 'Chapter' order right now)
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # ordered_members go from 0 to fileset_count + 1
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[fileset_count + 1].title.first

      # this control is styled as a drop-down but is actually a button & list, hence click_link not select
      click_link "Chapter \u25BC"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # [0] would be the representative file, not shown on this page...
      # this is the outlier file as it was uploaded second (shows up second last)
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Chapter \u25B2"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # essentially default sort, sans score, last uploaded is first
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[fileset_count + 1].title.first

      click_link "Format \u25BC"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # highest resource_type is the fileset_outlier, second ordered member, set to 'video' above
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Format \u25B2"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # lowest resource_type is the 3rd ordered member (first using the audio sequence, should be set to 'audio0001')
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[2].title.first

      click_link "Year \u25BC"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # highest year is the fileset_outlier, second ordered member [0, 1,... ], manually set to '2000' above
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[1].title.first

      click_link "Year \u25B2"
      first_fileset_link_text = page.first('.documentHeader .index_title a').text
      # lowest year is the third ordered member, the first to use the factory's sequence and set to '1900'
      expect(first_fileset_link_text).to eq monograph.ordered_members.to_a[2].title.first
    end
  end
end
