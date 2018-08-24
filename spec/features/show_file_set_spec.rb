# frozen_string_literal: true

require 'rails_helper'

describe 'FileSet Browse' do
  context 'Navigating forward/backward' do
    let(:user) { create(:platform_admin) }
    let(:cover) { create(:file_set, title: ['Representative']) }
    let(:monograph) { create(:monograph, user: user, title: ['Browse Me'], representative_id: cover.id) }
    let(:fileset_count) { 3 }

    before do
      stub_out_redis
      cosign_login_as user
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
end
