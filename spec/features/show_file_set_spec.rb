# frozen_string_literal: true

require 'rails_helper'

describe 'FileSet Browse' do
  before do
    stub_out_redis
    stub_out_irus
  end

  context 'Navigating forward/backward' do
    let(:user) { create(:platform_admin) }
    let(:cover) { create(:file_set, title: ['Representative']) }
    let(:monograph) { create(:monograph, user: user, title: ['Browse Me'], representative_id: cover.id) }
    let(:fileset_count) { 3 }

    before do
      login_as user
      monograph.ordered_members << cover

      fileset_count.times do
        monograph.ordered_members << FactoryBot.create(:file_set)
      end

      monograph.save!
      FileSet.all.each(&:save!)
    end

    it 'navigation arrows' do
      # no arrow links from representative FileSet (cover)
      visit hyrax_file_set_path(monograph.ordered_members.to_a[0].id)
      expect(page).not_to have_link(nil, href: monograph.ordered_members.to_a[1].id)

      # no arrow link to representative FileSet
      visit hyrax_file_set_path(monograph.ordered_members.to_a[1].id)
      expect(page).not_to have_link(nil, href: monograph.ordered_members.to_a[0].id)

      # arrow links show on non-representative monograph FileSets
      visit hyrax_file_set_path(monograph.ordered_members.to_a[2].id)
      expect(page).to have_link('Previous', href: monograph.ordered_members.to_a[1].id)
      expect(page).to have_link('Next', href: monograph.ordered_members.to_a[3].id)
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
