# frozen_string_literal: true

require 'rails_helper'

describe 'FileSet Browse' do
  before do
    stub_out_redis
    stub_out_irus
  end

  context 'Navigating forward/backward' do
    context 'public/anonymous user visiting a published Monograph' do
      let(:cover) { create(:public_file_set, title: ['Representative']) }
      let(:epub) { create(:public_file_set, title: ['EPUB']) }
      let(:tombstoned_file_set) { create(:public_file_set, title: ['Tombstone'], tombstone: 'yes') }
      let(:monograph) { create(:public_monograph, title: ['Browse Me'], representative_id: cover.id) }
      let(:fileset_count) { 3 }
      let!(:fr) { FeaturedRepresentative.create(work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

      before do
        monograph.ordered_members << cover

        fileset_count.times do
          monograph.ordered_members << FactoryBot.create(:public_file_set)
        end

        monograph.ordered_members << FactoryBot.create(:file_set) << FactoryBot.create(:public_file_set)
        monograph.ordered_members << tombstoned_file_set << epub << FactoryBot.create(:public_file_set)

        monograph.save!
        FileSet.all.each(&:save!)
      end

      it 'displays prev/next navigation arrows to published resources only' do
        # there is no link to the cover show page in the public-facing app, but if a non-Hyrax user arrives here,...
        # they get bounced to the Monograph catalog page
        visit hyrax_file_set_path(monograph.ordered_members.to_a[0].id)
        expect(page.current_path).to eql(hyrax_monograph_path(monograph.id))

        visit hyrax_file_set_path(monograph.ordered_members.to_a[1].id)
        # there is no link back to the cover
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[0].id)
        # next arrow link to resource FileSet
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[2].id)

        # arrow links point to both non-representative neighbor FileSets ("resources")
        visit hyrax_file_set_path(monograph.ordered_members.to_a[2].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[1].id)
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[3].id)

        visit hyrax_file_set_path(monograph.ordered_members.to_a[3].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[2].id)
        # no link to the draft file_set...
        expect(page).to_not have_link('Next', href: monograph.ordered_members.to_a[4].id)
        # ... instead that next link points to the public resource next in line
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[5].id)

        visit hyrax_file_set_path(monograph.ordered_members.to_a[5].id)
        # no link back to the draft neighbor....
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[4].id)
        # ... instead that previous link points to the public resource one further back
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[3].id)
        # no next link to the tombstone or EPUB representative...
        expect(page).to_not have_link('Next', href: monograph.ordered_members.to_a[6].id)
        expect(page).to_not have_link('Next', href: monograph.ordered_members.to_a[7].id)
        # ... instead the next link goes to the final published resource
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[8].id)

        visit hyrax_file_set_path(monograph.ordered_members.to_a[8].id)
        # no previous link to the tombstone or EPUB representative...
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[7].id)
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[6].id)
        # ... instead the previous link goes to the previous published resource
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[5].id)
        # no next link at all, this is the end of the chain
        expect(page).to_not have_link('Next')
      end
    end

    context 'admin reviewing a draft Monograph' do
      # note this is the same setup as above only with all FileSets in draft mode
      let(:user) { create(:platform_admin) }
      let(:cover) { create(:file_set, title: ['Representative']) }
      let(:epub) { create(:file_set, title: ['EPUB']) }
      let(:tombstoned_file_set) { create(:file_set, title: ['Tombstone'], tombstone: 'yes') }
      let(:monograph) { create(:monograph, title: ['Browse Me'], representative_id: cover.id) }
      let(:fileset_count) { 5 }
      let!(:fr) { FeaturedRepresentative.create(work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

      before do
        login_as user

        monograph.ordered_members << cover

        fileset_count.times do
          monograph.ordered_members << FactoryBot.create(:file_set)
        end

        monograph.ordered_members << tombstoned_file_set << epub << FactoryBot.create(:file_set)

        monograph.save!
        FileSet.all.each(&:save!)
      end

      it 'navigation arrows' do
        # admins can get to the cover show page through the "Manage Monograph and Files" page. They are unlikely to...
        # do this, however.
        visit hyrax_file_set_path(monograph.ordered_members.to_a[0].id)
        # there is no previous link as this is the first ordered_member
        expect(page).not_to have_link('Previous')
        # admin sees a next link even though this FileSet is draft
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[1].id)

        visit hyrax_file_set_path(monograph.ordered_members.to_a[1].id)
        # there is no link back to the cover, even for an admin
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[0].id)
        # next arrow link to resource FileSet, even though it is draft
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[2].id)

        # arrow links point to both non-representative neighbor FileSets ("resources"), even though they are draft
        visit hyrax_file_set_path(monograph.ordered_members.to_a[2].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[1].id)
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[3].id)

        # arrow links point to both non-representative neighbor FileSets ("resources"), even though they are draft
        visit hyrax_file_set_path(monograph.ordered_members.to_a[3].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[2].id)
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[4].id)

        # arrow links point to both non-representative neighbor FileSets ("resources"), even though they are draft
        visit hyrax_file_set_path(monograph.ordered_members.to_a[4].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[3].id)
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[5].id)

        # arrow links point to both non-representative neighbor FileSets ("resources"), even though they are draft
        visit hyrax_file_set_path(monograph.ordered_members.to_a[5].id)
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[4].id)
        # no next link to the tombstone or EPUB representative...
        expect(page).to_not have_link('Next', href: monograph.ordered_members.to_a[6].id)
        expect(page).to_not have_link('Next', href: monograph.ordered_members.to_a[7].id)
        # ... instead the next link goes to the final published resource
        expect(page).to have_link('Next', href: monograph.ordered_members.to_a[8].id)

        visit hyrax_file_set_path(monograph.ordered_members.to_a[8].id)
        # no previous link to the tombstone or EPUB representative...
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[7].id)
        expect(page).not_to have_link('Previous', href: monograph.ordered_members.to_a[6].id)
        # ... instead the previous link goes to the previous published resource
        expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[5].id)
        # no next link at all, this is the end of the chain
        expect(page).to_not have_link('Next')
      end
    end
  end

  describe 'Content warnings' do
    let(:fileset) { create(:public_file_set, content_warning: content_warning) }

    context 'No content warning set' do
      let(:content_warning) { nil }

      it 'Does not show the blocking dialog or content-hiding wrapper' do
        visit hyrax_file_set_path(fileset.id)
        expect(page).to_not have_css('#content-warning-media-consent')
        expect(page).to_not have_css('#content-warning-media', visible: false)
      end
    end

    context 'Content warning is set' do
      let(:content_warning) { 'this is the content warning' }

      it 'Shows the blocking dialog and content-hiding wrapper' do
        visit hyrax_file_set_path(fileset.id)
        expect(page).to have_css('#content-warning-media-consent')
        expect(page).to have_css('#content-warning-media', visible: false)
      end
    end
  end
end
