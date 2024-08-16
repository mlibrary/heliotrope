# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CSB Share Links for Draft Monographs" do
  let(:platform_admin) { create(:platform_admin) }

  # note `share_links: true` not needed here, that only controls the button to create a share link
  let(:press) { create(:press) }

  let(:public_monograph) { create(:public_monograph, press: press.subdomain) }
  let(:draft_monograph) { create(:monograph, press: press.subdomain) }
  let(:draft_monograph_to_share) { create(:monograph, press: press.subdomain) }

  let(:public_epub) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
  let(:draft_epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
  let(:draft_epub_to_share) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }

  let(:valid_share_token) do
    JsonWebToken.encode(data: draft_monograph_to_share.id, exp: Time.now.to_i + 28 * 24 * 3600)
  end

  before do
    FeaturedRepresentative.destroy_all

    3.times do
      public_monograph.ordered_members << FactoryBot.create(:public_file_set)
    end
    public_monograph.ordered_members << public_epub

    3.times do
      draft_monograph.ordered_members << FactoryBot.create(:file_set)
    end
    draft_monograph.ordered_members << draft_epub

    3.times do
      draft_monograph_to_share.ordered_members << FactoryBot.create(:file_set)
    end
    draft_monograph_to_share.ordered_members << draft_epub_to_share

    public_monograph.save!
    draft_monograph.save!
    draft_monograph_to_share.save!
    FileSet.all.each(&:save!)

    FeaturedRepresentative.create!(work_id: public_monograph.id, file_set_id: public_epub.id, kind: 'epub')
    FeaturedRepresentative.create!(work_id: draft_monograph.id, file_set_id: draft_epub.id, kind: 'epub')
    FeaturedRepresentative.create!(work_id: draft_monograph_to_share.id, file_set_id: draft_epub_to_share.id, kind: 'epub')

    UnpackJob.perform_now(public_epub.id, 'epub')
    UnpackJob.perform_now(draft_epub.id, 'epub')
    UnpackJob.perform_now(draft_epub_to_share.id, 'epub')
  end

  context 'Anonymous User' do
    context 'Greensub not involved' do
      context 'Public Monograph' do
        it "can view the public EPUB in CSB" do
          visit epub_path(id: public_epub.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title public_monograph.title.first
          expect(page).to have_css("meta[name='citation_title'][content='Ebook of #{public_monograph.title.first}']", visible: false)
        end

        it "can view the public Monograph and see the attached public FileSets" do
          visit monograph_catalog_path(id: public_monograph.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title public_monograph.title.first
          expect(page).to have_css('article.blacklight-fileset', count: 3)
        end

        it "can view the attached public FileSets" do
          first_file_set = public_monograph.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title first_file_set.title.first
        end
      end

      context 'Draft Monograph' do
        it "cannot view the draft EPUB in CSB" do
          visit epub_path(id: draft_epub.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_css("meta[name='citation_title'][content='Ebook of #{draft_monograph.title.first}']", visible: false)
        end

        it "cannot view the draft Monograph and see the attached public FileSets" do
          visit monograph_catalog_path(id: draft_monograph.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_css('article.blacklight-fileset', count: 3)
        end

        it "cannot view the attached draft FileSets" do
          first_file_set = draft_monograph.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_title first_file_set.title.first
        end
      end

      context 'Draft Monograph with Share Link' do
        it "can view the draft EPUB in CSB" do
          visit epub_path(id: draft_epub_to_share.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title draft_monograph_to_share.title.first
          expect(page).to have_css("meta[name='citation_title'][content='Ebook of #{draft_monograph_to_share.title.first}']", visible: false)
        end

        it "can view the draft Monograph and see the attached draft FileSets" do
          visit monograph_catalog_path(id: draft_monograph_to_share.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title draft_monograph_to_share.title.first
          expect(page).to have_css('article.blacklight-fileset', count: 3)
        end

        it "can view the attached draft FileSets" do
          first_file_set = draft_monograph_to_share.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title first_file_set.title.first
        end
      end
    end

    context 'Greensub involved' do
      let(:public_monograph_parent) { Sighrax.from_noid(public_monograph.id) }
      let(:draft_monograph_parent) { Sighrax.from_noid(draft_monograph.id) }
      let(:draft_monograph_to_share_parent) { Sighrax.from_noid(draft_monograph_to_share.id) }

      before do
        Greensub::Component.create!(identifier: public_monograph_parent.resource_token,
                                    name: public_monograph_parent.title,
                                    noid: public_monograph_parent.noid)
        Greensub::Component.create!(identifier: draft_monograph_parent.resource_token,
                                    name: draft_monograph_parent.title,
                                    noid: draft_monograph_parent.noid)
        Greensub::Component.create!(identifier: draft_monograph_to_share_parent.resource_token,
                                    name: draft_monograph_to_share_parent.title,
                                    noid: draft_monograph_to_share_parent.noid)
      end

      context 'Public Monograph' do
        it "Cannot view the public EPUB in CSB, as it is part of a protected Component" do
          visit epub_path(id: public_epub.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_css("meta[name='citation_title'][content='Ebook of #{public_monograph.title.first}']", visible: false)
        end

        it "can view the public Monograph and see the attached public FileSets" do
          visit monograph_catalog_path(id: public_monograph.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title public_monograph.title.first
          expect(page).to have_css('article.blacklight-fileset', count: 3)
        end

        it "can view the attached public FileSets" do
          first_file_set = public_monograph.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title first_file_set.title.first
        end
      end

      context 'Draft Monograph' do
        it "cannot view the draft EPUB in CSB" do
          visit epub_path(id: draft_epub.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_css("meta[name='citation_title'][content='Ebook of #{draft_monograph.title.first}']", visible: false)
        end

        it "cannot view the draft Monograph and see the attached public FileSets" do
          visit monograph_catalog_path(id: draft_monograph.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_css('article.blacklight-fileset', count: 3)
        end

        it "cannot view the attached draft FileSets" do
          first_file_set = draft_monograph.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id)
          expect(page.status_code).to eq(200)
          expect(page).to have_title "Authentication"
          expect(page).not_to have_title first_file_set.title.first
        end
      end

      context 'Draft Monograph with Share Link' do
        it "can view the draft EPUB in CSB" do
          visit epub_path(id: draft_epub_to_share.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title draft_monograph_to_share.title.first
          expect(page).to have_css("meta[name='citation_title'][content='Ebook of #{draft_monograph_to_share.title.first}']", visible: false)
        end

        it "can view the draft Monograph and see the attached draft FileSets" do
          visit monograph_catalog_path(id: draft_monograph_to_share.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title draft_monograph_to_share.title.first
          expect(page).to have_css('article.blacklight-fileset', count: 3)
        end

        it "can view the attached draft FileSets" do
          first_file_set = draft_monograph_to_share.ordered_members.to_a[0]
          visit hyrax_file_set_path(id: first_file_set.id, share: valid_share_token)
          expect(page.status_code).to eq(200)
          expect(page).to have_title first_file_set.title.first
        end
      end
    end
  end
end
