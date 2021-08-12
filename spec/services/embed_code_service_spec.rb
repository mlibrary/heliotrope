# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedCodeService do
  describe "when UnpackJob uses EmbedCodeService on an EPUB file with embeds" do
    before do
      travel_to(Time.parse("2022-01-01"))
    end

    let(:monograph) { create(:monograph, representative_id: cover.id) }
    let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

    let(:cover) { create(:file_set, label: 'cover.jpg') }
    let(:epub) { create(:file_set, label: 'fake_epub_with_embeds.epub', content: File.open(File.join(fixture_path, 'fake_epub_with_embeds.epub'))) }
    let(:image) { create(:file_set, label: 'image.jpg') }
    let(:audio) { create(:file_set, label: 'audio.mp3') }
    let(:video) { create(:file_set, label: 'video.mp4') }
    let(:interactive_map) { create(:file_set, label: 'interactive_map.zip', resource_type: ['interactive map']) }

    let(:cover_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(cover.id)) }
    let(:epub_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(epub.id)) }
    let(:image_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(image.id)) }
    let(:audio_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(audio.id)) }
    let(:video_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(video.id)) }
    let(:interactive_map_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(interactive_map.id)) }

    let(:cover_embed_attributes) { "div[@data-href=\"#{cover_embed_url}\"][@data-title=\"#{cover.title.first}\"][@data-resource-type=\"image\"]" }
    let(:epub_embed_attributes) { "[@data-href=\"#{epub_embed_url}\"][@data-title=\"#{epub.title.first}\"][@data-resource-type=\"resource\"]" }
    let(:image_embed_attributes) { "[@data-href=\"#{image_embed_url}\"][@data-title=\"#{image.title.first}\"][@data-resource-type=\"image\"]" }
    let(:audio_embed_attributes) { "[@data-href=\"#{audio_embed_url}\"][@data-title=\"#{audio.title.first}\"][@data-resource-type=\"audio\"]" }
    let(:video_embed_attributes) { "[@data-href=\"#{video_embed_url}\"][@data-title=\"#{video.title.first}\"][@data-resource-type=\"video\"]" }
    let(:interactive_map_embed_attributes) { "[@data-href=\"#{interactive_map_embed_url}\"][@data-title=\"#{interactive_map.title.first}\"][@data-resource-type=\"interactive-map\"]" }

    # mime_type is indexed by jobs that are not run here, these lines give presenters that delegate to Solr docs...
    # which can correctly respond to `HeliotropeMimeTypes` methods. Several presenter methods require these also.
    let(:image_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(image.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }
    let(:audio_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
    let(:video_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
    # mime_type not needed here, the switch is on resource_type metadata value
    let(:interactive_map_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_map.to_solr), nil) }

    before do
      FeaturedRepresentative.create(work_id: monograph.id, file_set_id: epub.id, kind: 'epub')
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [monograph.id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).and_call_original
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([image_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [interactive_map.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([interactive_map_presenter])
    end

    after { FeaturedRepresentative.destroy_all }

    context 'Monograph has no resources matching those referenced in the EPUB' do
      before do
        monograph.ordered_members << cover << epub
        [monograph, cover, epub].each { |item| item.save! }
        UnpackJob.perform_now(epub.id, 'epub')
      end

      it "Does not insert embed codes for the Monograph's representative files" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml')))
        expect(doc.search(cover_embed_attributes)).to be_empty
        expect(doc.search(epub_embed_attributes)).to be_empty
      end

      it "Does not insert embed codes for referenced files that don't exist on the Monograph" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
        expect(doc.search(image_embed_attributes)).to be_empty
        expect(doc.search(audio_embed_attributes)).to be_empty
        expect(doc.search(video_embed_attributes)).to be_empty
        expect(doc.search(interactive_map_embed_attributes)).to be_empty
      end
    end

    context 'Monograph has non-representative resources matching those referenced in the EPUB' do
      before do
        monograph.ordered_members << cover << epub << image << audio << video << interactive_map
        [monograph, epub, image, audio, video, interactive_map].each { |item| item.save! }
        UnpackJob.perform_now(epub.id, 'epub')
      end

      it "Does not insert embed codes for the Monograph's representative files" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml')))
        expect(doc.search(cover_embed_attributes)).to be_empty
        expect(doc.search(epub_embed_attributes)).to be_empty
      end

      it "Inserts embed codes for files referenced in the EPUB using data attributes" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
        expect(doc.search(image_embed_attributes).size).to eq(1)
        expect(doc.search(audio_embed_attributes).size).to eq(2) # one is a no-local-image example
        expect(doc.search(video_embed_attributes).size).to eq(1)
        expect(doc.search(interactive_map_embed_attributes).size).to eq(1)
      end

      it "Inserts embed codes for files referenced in the EPUB using img src basename matching" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
        expect(doc.search(image_embed_attributes).size).to eq(1)
        expect(doc.search(audio_embed_attributes).size).to eq(1)
        expect(doc.search(video_embed_attributes).size).to eq(1)
        expect(doc.search(interactive_map_embed_attributes).size).to eq(1)
        # check parent `p.image` tags are changed to <div> tags
        expect(doc.search("div[@class='image']").count).to eq(4)
      end

      it "Does not insert embed codes for files referenced in the EPUB using img src basename matching if `data-fulcrum-embed='false'` is present" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames_prevented.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames_prevented.xhtml')))
        expect(doc.search(image_embed_attributes)).to be_empty
        expect(doc.search(audio_embed_attributes)).to be_empty
        expect(doc.search(video_embed_attributes)).to be_empty
        expect(doc.search(interactive_map_embed_attributes)).to be_empty
        # check parent `p.image` tags are *not* changed to <div> tags
        expect(doc.search("p[@class='image']").count).to eq(4)
      end

      context "Monograph has more than one filename matching the EPUB file references" do
        let(:image_same_filename) { create(:file_set, label: 'image.jpg') }
        let(:audio_same_filename) { create(:file_set, label: 'audio.mp3') }
        let(:video_same_filename) { create(:file_set, label: 'video.mp4') }
        let(:interactive_map_same_filename) { create(:file_set, label: 'interactive_map.zip', resource_type: ['interactive map']) }

        before do
          ordered_members = [cover, epub, image, image_same_filename, audio, audio_same_filename, video,
                             video_same_filename, interactive_map, interactive_map_same_filename]
          monograph.ordered_members = ordered_members
          monograph.save!
          ordered_members.each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it "Does not insert embed codes for files referenced in the EPUB using data attributes" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
        end

        it "Does not insert embed codes for files referenced in the EPUB using img src basename matching" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          # check parent `p.image` tags are *not* changed to <div> tags
          expect(doc.search("p[@class='image']").count).to eq(4)
        end
      end

      context "Monograph has more than one file basename matching the EPUB file references" do
        let(:image_same_basename) { create(:file_set, label: 'image.png') }
        let(:audio_same_basename) { create(:file_set, label: 'audio.ogg') }
        let(:video_same_basename) { create(:file_set, label: 'video.webm') }
        let(:interactive_map_same_basename) { create(:file_set, label: 'interactive_map.zipx', resource_type: ['interactive map']) }

        # mime_type is indexed by jobs that are not run here, these lines give presenters that delegate to Solr docs...
        # which can correctly respond to `HeliotropeMimeTypes` methods. Several presenter methods require these also.
        let(:image_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(image_same_basename.to_solr.merge(mime_type_ssi: 'image/png')), nil) }
        let(:audio_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_same_basename.to_solr.merge(mime_type_ssi: 'audio/ogg')), nil) }
        let(:video_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_same_basename.to_solr.merge(mime_type_ssi: 'video/webm')), nil) }
        # mime_type not needed here, the switch is on resource_type metadata value
        let(:interactive_map_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_map_same_basename.to_solr), nil) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([image_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [interactive_map.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([interactive_map_presenter])

          ordered_members = [cover, epub, image, image_same_basename, audio, audio_same_basename, video,
                             video_same_basename, interactive_map, interactive_map_same_basename]
          monograph.ordered_members = ordered_members
          monograph.save!
          ordered_members.each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it "Inserts embed codes for files referenced in the EPUB using data attributes" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(image_embed_attributes).size).to eq(1)
          expect(doc.search(audio_embed_attributes).size).to eq(2) # one is a no-local-image example
          expect(doc.search(video_embed_attributes).size).to eq(1)
          expect(doc.search(interactive_map_embed_attributes).size).to eq(1)
        end

        it "Does not insert embed codes for files referenced in the EPUB using img src basename matching" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          # check parent `p.image` tags are *not* changed to <div> tags
          expect(doc.search("p[@class='image']").count).to eq(4)
        end
      end

      context "EPUB embeds do not use correct casing on filenames or file basenames and/or have hyphens" do
        let(:weird_case_image) { create(:file_set, label: 'image1.jpg') } # referenced with incorrect casing in `fake_epub_with_embeds.epub`
        let(:hyphen_video) { create(:file_set, label: 'hyphen-video.mp4') }
        let(:hyphen_weird_casing_interactive_map) { create(:file_set, label: 'hyphen-interactive-map.zip', resource_type: ['interactive map']) } # referenced with incorrect casing in `fake_epub_with_embeds.epub`

        let(:weird_case_image_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(weird_case_image.id)) }
        let(:hyphen_video_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(hyphen_video.id)) }
        let(:hyphen_weird_casing_interactive_map_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet.path(hyphen_weird_casing_interactive_map.id)) }

        let(:weird_case_image_embed_attributes) { "[@data-href=\"#{weird_case_image_embed_url}\"][@data-title=\"#{weird_case_image.title.first}\"][@data-resource-type=\"image\"]" }
        let(:hyphen_video_embed_attributes) { "[@data-href=\"#{hyphen_video_embed_url}\"][@data-title=\"#{hyphen_video.title.first}\"][@data-resource-type=\"video\"]" }
        let(:hyphen_weird_casing_interactive_map_embed_attributes) { "[@data-href=\"#{hyphen_weird_casing_interactive_map_embed_url}\"][@data-title=\"#{hyphen_weird_casing_interactive_map.title.first}\"][@data-resource-type=\"interactive-map\"]" }

        let(:weird_case_image_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(weird_case_image.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }
        let(:hyphen_video_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(hyphen_video.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:hyphen_weird_casing_interactive_map_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(hyphen_weird_casing_interactive_map.to_solr), nil) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [weird_case_image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([weird_case_image_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [hyphen_video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([hyphen_video_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [hyphen_weird_casing_interactive_map.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([hyphen_weird_casing_interactive_map_presenter])

          monograph.ordered_members << weird_case_image << audio << hyphen_video << hyphen_weird_casing_interactive_map
          [monograph, weird_case_image, audio, hyphen_video, hyphen_weird_casing_interactive_map].each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it 'Successfully finds the file and inserts the embed code anyway' do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_filename_testing.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_filename_testing.xhtml')))
          # check parent `p.image` tags are changed to <div> tags for the two <img> `src` basename embeds
          expect(doc.search("div[@class='image']").count).to eq(2)
          expect(doc.search(weird_case_image_embed_attributes).size).to eq(1)
          expect(doc.search(audio_embed_attributes).size).to eq(2) # one is a no-local-image example
          expect(doc.search(hyphen_video_embed_attributes).size).to eq(1)
          expect(doc.search(hyphen_weird_casing_interactive_map_embed_attributes).size).to eq(1)
        end
      end

      context "The EPUB being unpacked was originally created before 20210826" do
        let(:monograph) { create(:monograph, representative_id: cover.id, date_uploaded: DateTime.new(2021, 6, 1, 4, 5, 0, '+0')) }

        before do
          monograph.ordered_members << cover << epub << image << audio << video << interactive_map
          [monograph, epub, image, audio, video, interactive_map].each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it "Does not insert embed codes for the Monograph's representative files" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml')))
          expect(doc.search(cover_embed_attributes)).to be_empty
          expect(doc.search(epub_embed_attributes)).to be_empty
        end

        it "Does not insert embed codes for files referenced in the EPUB using data attributes" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
        end

        it "Does not insert embed codes for files referenced in the EPUB using img src basename matching" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          # check parent `p.image` tags are not changed to <div> tags
          expect(doc.search("div[@class='image']")).to be_empty
        end
      end
    end
  end
end
