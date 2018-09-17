# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpackJob, type: :job do
  describe "perform" do
    context "with an epub" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      it "unzips the epub and creates the database" do
        described_class.perform_now(epub.id, 'epub')
        expect(File.exist?(File.join(root_path, epub.id + '.db'))).to be true
      end
    end

    context "with a webgl" do
      let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
      let(:root_path) { UnpackService.root_path_from_noid(webgl.id, 'webgl') }

      it "unzips the webgl" do
        described_class.perform_now(webgl.id, 'webgl')
        expect(File.exist?(File.join(root_path, "Build", "UnityLoader.js"))).to be true
      end
    end

    context "with an epub and pre-existing webgl" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let!(:fre) { create(:featured_representative, monograph_id: 'mono_id', file_set_id: epub.id, kind: 'epub') }
      let!(:frw) { create(:featured_representative, monograph_id: 'mono_id', file_set_id: '123456789', kind: 'webgl') }
      let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

      after { FeaturedRepresentative.destroy_all }

      it "creates the epub-webgl map" do
        described_class.perform_now(epub.id, 'epub')
        expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
      end
    end

    context "with a pre-existing epub" do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }

      before do
        # we need the epub already unpacked in order to store the epub-webgl map file
        described_class.perform_now(epub.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      context "adding a webgl" do
        let(:webgl) { create(:file_set, content: File.open(File.join(fixture_path, 'fake-game.zip'))) }
        let!(:fre) { create(:featured_representative, monograph_id: 'mono_id', file_set_id: epub.id, kind: 'epub') }
        let!(:frw) { create(:featured_representative, monograph_id: 'mono_id', file_set_id: webgl.id, kind: 'webgl') }
        # The root_path of the epub, not the webgl is used to test
        let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

        it "creates the epub-webgl map" do
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be false
          described_class.perform_now(webgl.id, 'webgl')
          expect(File.exist?(File.join(root_path, 'epub-webgl-map.json'))).to be true
        end
      end
    end
  end
end
