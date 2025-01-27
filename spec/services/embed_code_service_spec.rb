# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedCodeService do
  # these responses need to be mocked prior to creating any YouTube-video FileSet
  before do
    oembed_response = Net::HTTPSuccess.new(1.0, '200', body: oembed_json)
    allow(oembed_response).to receive(:body).and_return(oembed_json)
    allow(Net::HTTP)
      .to receive(:get_response)
            .with(URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=goodyoutubeid&format=json"))
            .and_return(oembed_response)

    youtube_video_page_response = Net::HTTPSuccess.new(1.0, '200', body: youtube_video_page_body)
    allow(youtube_video_page_response).to receive(:body).and_return(youtube_video_page_body)
    allow(Net::HTTP)
      .to receive(:get_response)
            .with(URI("https://www.youtube.com/watch?v=goodyoutubeid"))
            .and_return(youtube_video_page_response)
  end

  describe "when UnpackJob uses EmbedCodeService on an EPUB file with embeds" do
    let(:monograph) { create(:monograph, representative_id: cover.id) }
    let(:root_path) { UnpackService.root_path_from_noid(epub.id, 'epub') }

    # This is for YouTube embeds (most values are obviously omitted from this oEmbed JSON snippet :-)
    let(:oembed_json) { '{"height":113,"width":200}' }
    let(:youtube_video_page_body) { "<body>...</body>" }

    let(:cover) { create(:file_set, label: 'cover.jpg') }
    let(:epub) { create(:file_set, label: 'fake_epub_with_embeds.epub', content: File.open(File.join(fixture_path, 'fake_epub_with_embeds.epub'))) }
    # the caption on `image` only serves to show that existing figcaptions within the EPUB take precedence
    let(:image) { create(:file_set, label: 'image.jpg', caption: ['Image file caption in FileSet metadata']) }
    let(:audio) { create(:file_set, label: 'audio.mp3', caption: ['Audio file caption in FileSet metadata']) }
    let(:video) { create(:file_set, label: 'video.mp4') }
    let(:youtube_video) { create(:file_set, identifier: ['youtube_id: goodyoutubeid']) }
    let(:interactive_application) { create(:file_set, label: 'interactive_application.zip', resource_type: ['interactive application']) }
    let(:interactive_map) { create(:file_set, label: 'interactive_map.zip', resource_type: ['interactive map']) }

    let(:cover_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + cover.id) }
    let(:epub_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + epub.id) }
    let(:image_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + image.id) }
    let(:audio_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + audio.id) }
    let(:video_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + video.id) }
    let(:youtube_video_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + youtube_video.id) }
    let(:interactive_application_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + interactive_application.id) }
    let(:interactive_map_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + interactive_map.id) }

    let(:cover_embed_attributes) { "div[@data-href=\"#{cover_embed_url}\"][@data-title=\"#{cover.title.first}\"][@data-resource-type=\"image\"]" }
    let(:epub_embed_attributes) { "[@data-href=\"#{epub_embed_url}\"][@data-title=\"#{epub.title.first}\"][@data-resource-type=\"resource\"]" }
    let(:image_embed_attributes) { "[@data-href=\"#{image_embed_url}\"][@data-title=\"#{image.title.first}\"][@data-resource-type=\"image\"]" }
    let(:audio_embed_attributes) { "[@data-href=\"#{audio_embed_url}\"][@data-title=\"#{audio.title.first}\"][@data-resource-type=\"audio\"]" }
    let(:video_embed_attributes) { "[@data-href=\"#{video_embed_url}\"][@data-title=\"#{video.title.first}\"][@data-resource-type=\"video\"]" }
    let(:youtube_video_embed_attributes) { "[@data-href=\"#{youtube_video_embed_url}\"][@data-title=\"#{youtube_video.title.first}\"][@data-resource-type=\"video\"]" }
    let(:interactive_application_embed_attributes) { "[@data-href=\"#{interactive_application_embed_url}\"][@data-title=\"#{interactive_application.title.first}\"][@data-resource-type=\"interactive-application\"]" }
    let(:interactive_map_embed_attributes) { "[@data-href=\"#{interactive_map_embed_url}\"][@data-title=\"#{interactive_map.title.first}\"][@data-resource-type=\"interactive-map\"]" }

    # mime_type is indexed by jobs that are not run here, these lines give presenters that delegate to Solr docs...
    # which can correctly respond to `HeliotropeMimeTypes` methods. Several presenter methods require these also.
    let(:cover_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(cover.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }
    let(:epub_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(epub.to_solr.merge(mime_type_ssi: 'application/epub+zip')), nil) }
    let(:image_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(image.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }
    let(:audio_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
    let(:video_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
    # mime_type not needed here, the switch is on the YouTube ID value in identifier
    let(:youtube_video_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(youtube_video.to_solr), nil) }
    # mime_type not needed here, the switch is on resource_type metadata value
    let(:interactive_application_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_application.to_solr), nil) }
    let(:interactive_map_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_map.to_solr), nil) }

    before do
      FeaturedRepresentative.create(work_id: monograph.id, file_set_id: epub.id, kind: 'epub')
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [monograph.id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).and_call_original
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([image_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [youtube_video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([youtube_video_presenter])
      allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [interactive_application.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([interactive_application_presenter])
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
        expect(doc.search("iframe[@src=\"#{cover_embed_url}\"]")).to be_empty
        expect(doc.search(epub_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{epub_embed_url}\"]")).to be_empty
      end

      it "Does not insert embed codes for referenced files that don't exist on the Monograph" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
        expect(doc.search(image_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{image_embed_url}\"]")).to be_empty
        expect(doc.search(audio_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]")).to be_empty
        expect(doc.search(video_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{video_embed_url}\"]")).to be_empty
        expect(doc.search(youtube_video_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]")).to be_empty
        expect(doc.search(interactive_application_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
        expect(doc.search(interactive_map_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
        # the `display:none` for the data attribute (additional resource) embeds off-Fulcrum are still present
        expect(doc.search("figure[@style]").size).to eq(9)
      end
    end

    context 'Monograph has non-representative resources matching those referenced in the EPUB' do
      before do
        monograph.ordered_members << cover << epub << image << audio << video << youtube_video << interactive_application << interactive_map
        [monograph, epub, image, audio, video, youtube_video, interactive_application, interactive_map].each { |item| item.save! }
        UnpackJob.perform_now(epub.id, 'epub')
      end

      it "Does not insert embed codes for the Monograph's representative files" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_representatives_no_embed.xhtml')))
        expect(doc.search(cover_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{cover_embed_url}\"]")).to be_empty
        expect(doc.search(epub_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{epub_embed_url}\"]")).to be_empty
      end

      context "Files referenced in the EPUB using data attributes" do
        it "inserts iframe embed codes for image, audio and video files" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{image_embed_url}\"]").size).to eq(1)
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]").size).to eq(2) # one is a no-local-image example
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{video_embed_url}\"]").size).to eq(1)
          expect(doc.search(youtube_video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]").size).to eq(1)
        end

        # HELIO-4788: Adding test for "Playback on other websites has been disabled by the video owner"
        context "YouTube video is not emdeddable" do
          before do
            oembed_response = Net::HTTPForbidden.new(1.0, '401', body: 'Unauthorized')
            allow(Net::HTTP)
              .to receive(:get_response)
                    .with(URI("https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=goodyoutubeid&format=json"))
                    .and_return(oembed_response)

            youtube_video.save!
            UnpackJob.perform_now(epub.id, 'epub')
          end

          it "Does not insert embed codes for the YouTube video" do
            expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
            doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
            expect(doc.search(youtube_video_embed_attributes)).to be_empty
            expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]")).to be_empty
          end
        end

        it "inserts CSB-modal embed codes for interactive JavaScript applications/maps" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(interactive_application_embed_attributes).size).to eq(2)
          expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_map_embed_attributes).size).to eq(2)
          expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
        end

        it 'removes the `style="display:none"` used to keep these additional-resource embeds hidden off-Fulcrum' do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          # all styles removed from additional resources (especially targeting the `display:none` needed off-Fulcrum)
          expect(doc.search("figure[@data-fulcrum-embed-filename][@style]")).to be_empty
        end
      end

      context "Figcaptions for embeds referenced using data attributes on figure" do
        it "are inserted at the end of the figures, only where none are present in the EPUB" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          # the image embed in this EPUB XHTML file already has a <figcaption> present,...
          # nothing is changed even though the FileSet has a (different) metadata caption.
          expect(doc.search("figcaption:contains('Image file caption in the EPUB file')").size).to eq(1)
          # the audio embeds don't have a <figcaption> present in the EPUB XHTML file,...
          # but the FileSet metadata has a caption, which will be added to both as a <figcaption>.
          expect(doc.search("figcaption:contains('Audio file caption in FileSet metadata')").size).to eq(2)
          # the video embed has a <figcaption> present in the EPUB XHTML file,...
          # and the FileSet metadata has no caption. Nothing is changed.
          expect(doc.search("figcaption:contains('Video file caption in the EPUB file')").size).to eq(1)
          # the YouTube video embed has a <figcaption> present in the EPUB XHTML file,...
          # and the FileSet metadata has no caption. Nothing is changed.
          expect(doc.search("figcaption:contains('YouTube video file caption in the EPUB file')").size).to eq(1)
          # the first interactive application embed doesn't have a <figcaption> present in the EPUB XHTML file,...
          # and the FileSet metadata has no caption. A generic <figcaption> is inserted.
          expect(doc.search("figcaption:contains('Additional Interactive Application Resource')").size).to eq(1)
          # the second interactive application has a <figcaption> present in the EPUB, so this is left as-is
          expect(doc.search("figcaption:contains('Fig. 1.5. An image representing the interactive application')").size).to eq(1)
          # the first interactive map embed doesn't have a <figcaption> present in the EPUB XHTML file,...
          # and the FileSet metadata has no caption. A generic <figcaption> is inserted.
          expect(doc.search("figcaption:contains('Additional Interactive Map Resource')").size).to eq(1)
          # the second interactive map has a <figcaption> present in the EPUB, so this is left as-is
          expect(doc.search("figcaption:contains('Fig. 1.7. An image representing the interactive map')").size).to eq(1)
        end

        it 'are always positioned after the iframe embeds or modal-embed-opening buttons' do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          figure = doc.search("figure[data-fulcrum-embed-filename='image.jpg']").first
          expect(figure.last_element_child.name).to eq('figcaption')

          expect(doc.search("figure[data-fulcrum-embed-filename='audio.mp3']").size).to eq(2)
          figure = doc.search("figure[data-fulcrum-embed-filename='audio.mp3']")[0]
          expect(figure.last_element_child.name).to eq('figcaption')
          figure = doc.search("figure[data-fulcrum-embed-filename='audio.mp3']")[1]
          expect(figure.last_element_child.name).to eq('figcaption')

          figure = doc.search("figure[data-fulcrum-embed-filename='video.mp4']").first
          expect(figure.last_element_child.name).to eq('figcaption')

          expect(doc.search("figure[data-fulcrum-embed-filename='interactive_application.zip']").size).to eq(2)
          figure = doc.search("figure[data-fulcrum-embed-filename='interactive_application.zip']")[0]
          expect(figure.last_element_child.name).to eq('figcaption')
          figure = doc.search("figure[data-fulcrum-embed-filename='interactive_application.zip']")[1]
          expect(figure.last_element_child.name).to eq('figcaption')

          expect(doc.search("figure[data-fulcrum-embed-filename='interactive_map.zip']").size).to eq(2)
          figure = doc.search("figure[data-fulcrum-embed-filename='interactive_map.zip']")[0]
          expect(figure.last_element_child.name).to eq('figcaption')
          figure = doc.search("figure[data-fulcrum-embed-filename='interactive_map.zip']")[1]
          expect(figure.last_element_child.name).to eq('figcaption')
        end
      end

      context "Inserts embed codes for files referenced in the EPUB using img src basename matching" do
        it "inserts iframe embed codes for image, audio and video files and removes the original img tags" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{image_embed_url}\"]").size).to eq(1)
          expect(doc.search("img[@alt=\"local image for image embed\"]")).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]").size).to eq(1)
          expect(doc.search("img[@alt=\"local image for audio embed\"]")).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{video_embed_url}\"]").size).to eq(1)
          expect(doc.search("img[@alt=\"local image for video embed\"]")).to be_empty
        end

        it "inserts CSB-modal embed codes for interactive JavaScript applications/maps, leaving their img tags in place" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(interactive_application_embed_attributes).size).to eq(1)
          expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search("img[@alt=\"local image for interactive application embed\"]").size).to eq(1)
          expect(doc.search(interactive_map_embed_attributes).size).to eq(1)
          expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
          expect(doc.search("img[@alt=\"local image for interactive map embed\"]").size).to eq(1)
        end

        it "Changes the imgs' parent p tags to div tags" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search("div[@class='image']").count).to eq(6)
        end
      end

      it "Does not insert any embed codes for files referenced in the EPUB using img src basename matching if `data-fulcrum-embed='false'` is present" do
        expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames_prevented.xhtml'))).to be true
        doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames_prevented.xhtml')))
        expect(doc.search(image_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{image_embed_url}\"]")).to be_empty
        expect(doc.search(audio_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]")).to be_empty
        expect(doc.search(video_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{video_embed_url}\"]")).to be_empty
        expect(doc.search(interactive_application_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
        expect(doc.search(interactive_map_embed_attributes)).to be_empty
        expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
        # check parent `p.image` tags are *not* changed to <div> tags
        expect(doc.search("p[@class='image']").count).to eq(6)
        # check the img tags have *not* been removed
        expect(doc.search("img").count).to eq(6)
      end

      context "Monograph has more than one filename (identifier in the case of YouTube vids) matching the EPUB file references" do
        let(:image_same_filename) { create(:file_set, label: 'image.jpg') }
        let(:audio_same_filename) { create(:file_set, label: 'audio.mp3') }
        let(:video_same_filename) { create(:file_set, label: 'video.mp4') }
        let(:youtube_video_same_identifier) { create(:file_set, identifier: ['youtube_id: goodyoutubeid']) }
        let(:interactive_application_same_filename) { create(:file_set, label: 'interactive_application.zip', resource_type: ['interactive application']) }
        let(:interactive_map_same_filename) { create(:file_set, label: 'interactive_map.zip', resource_type: ['interactive map']) }

        before do
          ordered_members = [cover, epub, image, image_same_filename, audio, audio_same_filename, video, youtube_video,
                             video_same_filename, youtube_video_same_identifier,
                             interactive_application, interactive_application_same_filename,
                             interactive_map, interactive_map_same_filename]
          monograph.ordered_members = ordered_members
          monograph.save!
          ordered_members.each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it "Does not insert embed codes for files referenced in the EPUB using data attributes" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{image_embed_url}\"]")).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]")).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{video_embed_url}\"]")).to be_empty
          expect(doc.search(youtube_video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_application_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
          # the `display:none` for the data attribute (additional resource) embeds off-Fulcrum are still present
          expect(doc.search("figure[@style]").size).to eq(9)
        end

        it "Does not insert embed codes for files referenced in the EPUB using img src basename matching" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{image_embed_url}\"]")).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]")).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{video_embed_url}\"]")).to be_empty
          expect(doc.search(youtube_video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_application_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
          # check parent `p.image` tags are *not* changed to <div> tags
          expect(doc.search("p[@class='image']").count).to eq(6)
          # check the img tags have *not* been removed
          expect(doc.search("img").count).to eq(6)
        end
      end

      context "Monograph has more than one file basename (identifier in the case of YouTube vids) matching the EPUB file references" do
        let(:image_same_basename) { create(:file_set, label: 'image.png') }
        let(:audio_same_basename) { create(:file_set, label: 'audio.ogg') }
        let(:video_same_basename) { create(:file_set, label: 'video.webm') }
        let(:youtube_video_same_identifier) { create(:file_set, identifier: ['youtube_id: goodyoutubeid']) }
        let(:interactive_application_same_basename) { create(:file_set, label: 'interactive_application.zipx', resource_type: ['interactive application']) }
        let(:interactive_map_same_basename) { create(:file_set, label: 'interactive_map.zipx', resource_type: ['interactive map']) }

        # mime_type is indexed by jobs that are not run here, these lines give presenters that delegate to Solr docs...
        # which can correctly respond to `HeliotropeMimeTypes` methods. Several presenter methods require these also.
        let(:image_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(image_same_basename.to_solr.merge(mime_type_ssi: 'image/png')), nil) }
        let(:audio_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_same_basename.to_solr.merge(mime_type_ssi: 'audio/ogg')), nil) }
        let(:video_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_same_basename.to_solr.merge(mime_type_ssi: 'video/webm')), nil) }
        # mime_type not needed here, the switch is on resource_type metadata value
        let(:interactive_application_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_application_same_basename.to_solr), nil) }
        let(:interactive_map_same_basename_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(interactive_map_same_basename.to_solr), nil) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([image_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [youtube_video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([youtube_video_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [interactive_application.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([interactive_application_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [interactive_map.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([interactive_map_presenter])

          ordered_members = [cover, epub, image, image_same_basename, audio, audio_same_basename, video,
                             video_same_basename, youtube_video, youtube_video_same_identifier,
                             interactive_application, interactive_application_same_basename,
                             interactive_map, interactive_map_same_basename]
          monograph.ordered_members = ordered_members
          monograph.save!
          ordered_members.each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        context "Inserts embed codes for *actual* files (not YouTube embeds which have no file extension to differentiate!) referenced in the EPUB using data attributes" do
          it "inserts iframe embed codes for image, audio and video files" do
            expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
            doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
            expect(doc.search(image_embed_attributes)).to be_empty
            expect(doc.search("iframe[@src=\"#{image_embed_url}\"]").size).to eq(1)
            expect(doc.search(audio_embed_attributes)).to be_empty
            expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]").size).to eq(2) # one is a no-local-image example
            expect(doc.search(video_embed_attributes)).to be_empty
            expect(doc.search("iframe[@src=\"#{video_embed_url}\"]").size).to eq(1)
            expect(doc.search(youtube_video_embed_attributes)).to be_empty
            expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]").size).to eq(0)
            # all styles removed from additional resources (especially targeting the `display:none` needed off-Fulcrum)
            # apart from YouTube embed, which was skipped for lack of file extension differentiator
            expect(doc.search("figure[@data-fulcrum-embed-filename][@style]").size).to eq(1)
          end

          it "Inserts CSB-modal embed codes for interactive Javascript applications/maps" do
            expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml'))).to be true
            doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_data_attributes.xhtml')))
            expect(doc.search(interactive_application_embed_attributes).size).to eq(2)
            expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
            expect(doc.search(interactive_map_embed_attributes).size).to eq(2)
            expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
            # all styles removed from additional resources (especially targeting the `display:none` needed off-Fulcrum)
            # apart from YouTube embed, which was skipped for lack of file extension differentiator
            expect(doc.search("figure[@data-fulcrum-embed-filename][@style]").size).to eq(1)
          end
        end

        it "Does not insert embed codes for files referenced in the EPUB using img src basename matching" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_using_img_src_basenames.xhtml')))
          expect(doc.search(image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{image_embed_url}\"]")).to be_empty
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]")).to be_empty
          expect(doc.search(video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{video_embed_url}\"]")).to be_empty
          expect(doc.search(youtube_video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{youtube_video_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_application_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search(interactive_map_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{interactive_map_embed_url}\"]")).to be_empty
          # check parent `p.image` tags are *not* changed to <div> tags
          expect(doc.search("p[@class='image']").count).to eq(6)
          # check the img tags have *not* been removed
          expect(doc.search("img").count).to eq(6)
        end
      end

      context "EPUB embeds do not use correct casing on filenames or file basenames and/or have hyphens" do
        let(:weird_case_image) { create(:file_set, label: 'image1.jpg') } # referenced with incorrect casing in `fake_epub_with_embeds.epub`
        let(:hyphen_video) { create(:file_set, label: 'hyphen-video.mp4') }
        let(:hyphen_weird_casing_interactive_application) { create(:file_set, label: 'hyphen-interactive-application.zip', resource_type: ['interactive application']) } # referenced with incorrect casing in `fake_epub_with_embeds.epub`
        let(:hyphen_weird_casing_interactive_map) { create(:file_set, label: 'hyphen-interactive-map.zip', resource_type: ['interactive map']) } # referenced with incorrect casing in `fake_epub_with_embeds.epub`

        let(:weird_case_image_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + weird_case_image.id) }
        let(:hyphen_video_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + hyphen_video.id) }
        let(:hyphen_weird_casing_interactive_application_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + hyphen_weird_casing_interactive_application.id) }
        let(:hyphen_weird_casing_interactive_map_embed_url) { Rails.application.routes.url_helpers.embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + hyphen_weird_casing_interactive_map.id) }

        let(:weird_case_image_embed_attributes) { "[@data-href=\"#{weird_case_image_embed_url}\"][@data-title=\"#{weird_case_image.title.first}\"][@data-resource-type=\"image\"]" }
        let(:hyphen_video_embed_attributes) { "[@data-href=\"#{hyphen_video_embed_url}\"][@data-title=\"#{hyphen_video.title.first}\"][@data-resource-type=\"video\"]" }
        let(:hyphen_weird_casing_interactive_application_embed_attributes) { "[@data-href=\"#{hyphen_weird_casing_interactive_application_embed_url}\"][@data-title=\"#{hyphen_weird_casing_interactive_application.title.first}\"][@data-resource-type=\"interactive-application\"]" }
        let(:hyphen_weird_casing_interactive_map_embed_attributes) { "[@data-href=\"#{hyphen_weird_casing_interactive_map_embed_url}\"][@data-title=\"#{hyphen_weird_casing_interactive_map.title.first}\"][@data-resource-type=\"interactive-map\"]" }

        let(:weird_case_image_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(weird_case_image.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }
        let(:hyphen_video_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(hyphen_video.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:hyphen_weird_casing_interactive_application_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(hyphen_weird_casing_interactive_application.to_solr), nil) }
        let(:hyphen_weird_casing_interactive_map_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(hyphen_weird_casing_interactive_map.to_solr), nil) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [weird_case_image.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([weird_case_image_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [hyphen_video.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([hyphen_video_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [hyphen_weird_casing_interactive_application.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([hyphen_weird_casing_interactive_application_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [hyphen_weird_casing_interactive_map.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([hyphen_weird_casing_interactive_map_presenter])

          monograph.ordered_members << weird_case_image << audio << hyphen_video << hyphen_weird_casing_interactive_application << hyphen_weird_casing_interactive_map
          [monograph, weird_case_image, audio, hyphen_video, hyphen_weird_casing_interactive_application, hyphen_weird_casing_interactive_map].each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it 'Successfully finds the file and inserts the embed code anyway' do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'spec_filename_testing.xhtml'))).to be true
          doc = Nokogiri::XML(File.read(File.join(root_path, 'EPUB', 'xhtml', 'spec_filename_testing.xhtml')))
          # check parent `p.image` tags are changed to <div> tags for the two <img> `src` basename embeds
          expect(doc.search("div[@class='image']").count).to eq(2)
          expect(doc.search(weird_case_image_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{weird_case_image_embed_url}\"]").size).to eq(1)
          expect(doc.search(audio_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{audio_embed_url}\"]").size).to eq(2) # one is a no-local-image example
          expect(doc.search(hyphen_video_embed_attributes)).to be_empty
          expect(doc.search("iframe[@src=\"#{hyphen_video_embed_url}\"]").size).to eq(1)
          expect(doc.search(hyphen_weird_casing_interactive_application_embed_attributes).size).to eq(1)
          expect(doc.search("iframe[@src=\"#{hyphen_weird_casing_interactive_application_embed_url}\"]")).to be_empty
          expect(doc.search(hyphen_weird_casing_interactive_map_embed_attributes).size).to eq(1)
          expect(doc.search("iframe[@src=\"#{hyphen_weird_casing_interactive_map_embed_url}\"]")).to be_empty
          # all styles removed from additional resources (especially targeting the `display:none` needed off-Fulcrum)
          expect(doc.search("figure[@data-fulcrum-embed-filename][@style]")).to be_empty
        end
      end

      context "Automatically-added Able Player headings" do
        # the image will not have any headings automatically added, anywhere
        let(:image_under_all_headings) { create(:file_set, label: 'image_under_all_headings.jpg', title: ['Image to be placed alongside all below, gets no headings']) }
        let(:image_under_all_headings_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(image_under_all_headings.to_solr.merge(mime_type_ssi: 'image/jpeg')), nil) }

        let(:audio_top_level) { create(:file_set, label: 'audio_top_level.mp3', title: ['Audio top level, will get h1']) }
        let(:audio_top_level_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_top_level.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        let(:audio_under_h1) { create(:file_set, label: 'audio_under_h1.mp3', title: ['Audio under a h1, will get h2']) }
        let(:audio_under_h1_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h1.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        let(:audio_under_h2) { create(:file_set, label: 'audio_under_h2.mp3', title: ['Audio under a h2, will get h3']) }
        let(:audio_under_h2_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h2.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        let(:audio_under_h3) { create(:file_set, label: 'audio_under_h3.mp3', title: ['Audio under a h3, will get h4']) }
        let(:audio_under_h3_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h3.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        let(:audio_under_h4) { create(:file_set, label: 'audio_under_h4.mp3', title: ['Audio under a h4, will get h5']) }
        let(:audio_under_h4_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h4.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        let(:audio_under_h5) { create(:file_set, label: 'audio_under_h5.mp3', title: ['Audio under a h5, will get h6']) }
        let(:audio_under_h5_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h5.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }
        # this one is very unlikely to happen, thankfully
        let(:audio_under_h6) { create(:file_set, label: 'audio_under_h6.mp3', title: ['Audio under a h6, will get h6']) }
        let(:audio_under_h6_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(audio_under_h6.to_solr.merge(mime_type_ssi: 'audio/mp3')), nil) }

        let(:video_top_level) { create(:file_set, label: 'video_top_level.mp4', title: ['Video top level, will get h1']) }
        let(:video_top_level_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_top_level.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:video_under_h1) { create(:file_set, label: 'video_under_h1.mp4', title: ['Video under a h1, will get h2']) }
        let(:video_under_h1_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h1.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:video_under_h2) { create(:file_set, label: 'video_under_h2.mp4', title: ['Video under a h2, will get h3']) }
        let(:video_under_h2_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h2.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:video_under_h3) { create(:file_set, label: 'video_under_h3.mp4', title: ['Video under a h3, will get h4']) }
        let(:video_under_h3_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h3.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:video_under_h4) { create(:file_set, label: 'video_under_h4.mp4', title: ['Video under a h4, will get h5']) }
        let(:video_under_h4_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h4.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        let(:video_under_h5) { create(:file_set, label: 'video_under_h5.mp4', title: ['Video under a h5, will get h6']) }
        let(:video_under_h5_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h5.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }
        # this one is very unlikely to happen, thankfully
        let(:video_under_h6) { create(:file_set, label: 'video_under_h6.mp4', title: ['Video under a h6, will get h6']) }
        let(:video_under_h6_presenter) { Hyrax::FileSetPresenter.new(SolrDocument.new(video_under_h6.to_solr.merge(mime_type_ssi: 'video/mp4')), nil) }


        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [image_under_all_headings.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([image_under_all_headings_presenter])

          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_top_level_presenter.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_top_level_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h1.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h1_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h2.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h2_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h3.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h3_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h4.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h4_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h5.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h5_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [audio_under_h6.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([audio_under_h6_presenter])

          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_top_level.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_top_level_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h1.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h1_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h2.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h2_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h3.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h3_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h4.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h4_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h5.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h5_presenter])
          allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [video_under_h6.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).and_return([video_under_h6_presenter])


          ordered_members = [cover, epub, image_under_all_headings,
                             audio_top_level, audio_under_h1, audio_under_h2, audio_under_h3, audio_under_h4, audio_under_h5, audio_under_h6,
                             video_top_level, video_under_h1, video_under_h2, video_under_h3, video_under_h4, video_under_h5, video_under_h6]
          monograph.ordered_members = ordered_members
          monograph.save!
          ordered_members.each { |item| item.save! }
          UnpackJob.perform_now(epub.id, 'epub')
        end

        it "Adds headings appropriate to the original DOM, for audio and video embeds only" do
          expect(File.exist?(File.join(root_path, 'EPUB', 'xhtml', 'embeds_heading_testing.xhtml'))).to be true

          enhanced_file = File.read(File.join(root_path, 'EPUB', 'xhtml', 'embeds_heading_testing.xhtml'))
          inline_sr_only_style = '"clip: rect(1px, 1px, 1px, 1px); clip-path: inset(50%); height: 1px; width: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute;"'

          expect(enhanced_file).not_to include("<h1 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h1>")
          expect(enhanced_file).not_to include("<h2 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h2>")
          expect(enhanced_file).not_to include("<h3 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h3>")
          expect(enhanced_file).not_to include("<h4 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h4>")
          expect(enhanced_file).not_to include("<h5 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h5>")
          expect(enhanced_file).not_to include("<h6 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h6>")
          expect(enhanced_file).not_to include("<h6 style=#{inline_sr_only_style}>Media player: #{image_under_all_headings.title.first}</h6>")

          expect(enhanced_file).to include("<h1 style=#{inline_sr_only_style}>Media player: #{audio_top_level.title.first}</h1>")
          expect(enhanced_file).to include("<h2 style=#{inline_sr_only_style}>Media player: #{audio_under_h1.title.first}</h2>")
          expect(enhanced_file).to include("<h3 style=#{inline_sr_only_style}>Media player: #{audio_under_h2.title.first}</h3>")
          expect(enhanced_file).to include("<h4 style=#{inline_sr_only_style}>Media player: #{audio_under_h3.title.first}</h4>")
          expect(enhanced_file).to include("<h5 style=#{inline_sr_only_style}>Media player: #{audio_under_h4.title.first}</h5>")
          expect(enhanced_file).to include("<h6 style=#{inline_sr_only_style}>Media player: #{audio_under_h5.title.first}</h6>")
          expect(enhanced_file).to include("<h6 style=#{inline_sr_only_style}>Media player: #{audio_under_h6.title.first}</h6>")

          expect(enhanced_file).to include("<h1 style=#{inline_sr_only_style}>Media player: #{video_top_level.title.first}</h1>")
          expect(enhanced_file).to include("<h2 style=#{inline_sr_only_style}>Media player: #{video_under_h1.title.first}</h2>")
          expect(enhanced_file).to include("<h3 style=#{inline_sr_only_style}>Media player: #{video_under_h2.title.first}</h3>")
          expect(enhanced_file).to include("<h4 style=#{inline_sr_only_style}>Media player: #{video_under_h3.title.first}</h4>")
          expect(enhanced_file).to include("<h5 style=#{inline_sr_only_style}>Media player: #{video_under_h4.title.first}</h5>")
          expect(enhanced_file).to include("<h6 style=#{inline_sr_only_style}>Media player: #{video_under_h5.title.first}</h6>")
          expect(enhanced_file).to include("<h6 style=#{inline_sr_only_style}>Media player: #{video_under_h6.title.first}</h6>")
        end
      end
    end
  end
end
