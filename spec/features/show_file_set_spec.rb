require 'rails_helper'

feature 'FileSet Browse' do
  context 'Navigating forward/backward' do
    let(:user) { create(:platform_admin) }
    let(:cover) { create(:file_set, title: ['Representative']) }
    let(:monograph) { create(:monograph, user: user, title: ['Browse Me'], representative_id: cover.id) }
    let(:section1) { create(:section, monograph_id: monograph.id) }
    let(:section2) { create(:section, monograph_id: monograph.id) }
    let(:section3) { create(:section, monograph_id: monograph.id) }
    let(:fileset_count) { 3 }

    before do
      stub_out_redis
      login_as user
      monograph.ordered_members << cover

      fileset_count.times do
        monograph.ordered_members << FactoryGirl.create(:file_set)
        section1.ordered_members << FactoryGirl.create(:file_set)
        section2.ordered_members << FactoryGirl.create(:file_set)
        section3.ordered_members << FactoryGirl.create(:file_set)
      end

      monograph.ordered_members << section1
      monograph.ordered_members << section2
      monograph.ordered_members << FactoryGirl.create(:file_set)
      monograph.ordered_members << section3
      monograph.save!
      Section.all.each(&:save!)
      FileSet.all.each(&:save!)
    end

    scenario 'navigation arrows' do
      # no arrow links from representative FileSet (cover)
      visit curation_concerns_file_set_path(monograph.ordered_members.to_a[0].id)
      expect(page).to_not have_link(nil, href: monograph.ordered_members.to_a[1].id)

      # no arrow link to representative FileSet
      visit curation_concerns_file_set_path(monograph.ordered_members.to_a[1].id)
      expect(page).to_not have_link(nil, href: monograph.ordered_members.to_a[0].id)

      # arrow links show on non-representative monograph FileSets
      visit curation_concerns_file_set_path(monograph.ordered_members.to_a[2].id)
      expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[1].id)
      expect(page).to have_link('Next', href: monograph.ordered_members.to_a[3].id)

      # TODO: fix array values when the reversing of Sections' FileSets is undone
      # arrow links show between FileSets within the same Section
      visit curation_concerns_file_set_path(section1.ordered_members.to_a[1].id)
      expect(page).to have_link('Next', href: section1.ordered_members.to_a[0].id)
      expect(page).to have_link('Previous', href: section1.ordered_members.to_a[2].id)

      # arrow links show between the last FileSet in one Section and the first FileSet in the next Section
      visit curation_concerns_file_set_path(section1.ordered_members.to_a[0].id)
      expect(page).to have_link('Next', href: section2.ordered_members.to_a[2].id)
      visit curation_concerns_file_set_path(section2.ordered_members.to_a[2].id)
      expect(page).to have_link('Previous', href: section1.ordered_members.to_a[0].id)

      # non-representative Monograph FileSet has links to neighboring FileSets in Sections
      visit curation_concerns_file_set_path(monograph.ordered_members.to_a[6].id)
      expect(page).to have_link('Previous', href: section2.ordered_members.to_a[0].id)
      expect(page).to have_link('Next', href: section3.ordered_members.to_a[2].id)
    end
  end
end
