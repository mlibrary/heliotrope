# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedCodePresenter do
  let(:ability) { double('ability') }
  let(:presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability) }
  let(:dimensionless_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability) }

  describe '#allow_embed?' do
    let(:press) { create(:press) }
    let(:monograph) { create(:monograph, press: press.subdomain) }
    let(:file_set) { create(:file_set) }
    let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
    end

    context 'no' do
      before { allow(ability).to receive(:platform_admin?).and_return(false) }

      it { expect(presenter.allow_embed?).to be false }
    end

    context 'yes' do
      before { allow(ability).to receive(:platform_admin?).and_return(true) }

      it { expect(presenter.allow_embed?).to be true }
    end
  end

  describe '#embeddable_type?' do
    subject { presenter.embeddable_type? }

    let(:file_set_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type, resource_type_tesim: [resource_type]) }
    let(:mime_type) { nil }
    let(:resource_type) { nil }

    context 'map' do
      let(:resource_type) { 'map' }

      it { is_expected.to be false }
    end

    context 'interactive map' do
      let(:resource_type) { 'interactive map' }

      it { is_expected.to be true }
    end

    context 'image' do
      let(:mime_type) { 'image/tiff' }

      it { is_expected.to be true }
    end

    context 'video' do
      let(:mime_type) { 'video/mp4' }

      it { is_expected.to be true }
    end

    context 'audio' do
      let(:mime_type) { 'audio/mp3' }

      it { is_expected.to be true }
    end

    context 'pdf' do
      let(:mime_type) { 'application/pdf' }

      it { is_expected.to be false }
    end

    context 'Word .doc' do
      let(:mime_type) { 'application/msword' }

      it { is_expected.to be false }
    end
  end

  # test the old-style (CSB-embed-targeting) embed codes with inline styles, as well as the equivalent CSS styles...
  # targeting style-less (more uniform) embed codes being by external parties, especially Janeway articles.
  describe '#embed_code and #embed_code_css' do
    let(:map_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'><!-- actual height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:map_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1920px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:60%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:dimensionless_map_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1000px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_map_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1000px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:60%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'><!-- actual image height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:image_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1920px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:60%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:portrait_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1080px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:80%; position:relative; height:0;'><!-- actual image height: 1920px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:portrait_image_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1080px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:80%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:square_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:500px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:80%; position:relative; height:0;'><!-- actual image height: 500px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:square_image_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:500px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:80%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:dimensionless_image_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1000px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:60%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_image_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1000px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:60%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:56.25%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1920px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:56.25%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:dimensionless_video_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1000px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:75%; position:relative; height:0;'>
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:dimensionless_video_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1000px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:75%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:video_with_visual_descriptions_embed_code) {
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:1920px; margin:auto; background-color:#000'>
          <div style='overflow:hidden; padding-bottom:67.5%; position:relative; height:0;'><!-- actual video height: 1080px -->
            <iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    }
    let(:video_with_visual_descriptions_embed_code_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
          width:auto;
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          max-width:1920px;
          margin:auto;
          background-color:#000;
        }
        #fulcrum-embed-inner-fileset_id {
          overflow:hidden;
          padding-bottom:67.5%;
          position:relative; height:0;
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          overflow:hidden;
          border-width:0;
          left:0; top:0;
          width:100%;
          height:100%;
          position:absolute;
        }
      END
    }
    let(:audio_embed_code_without_transcript) {
      "<iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; height:125px; margin:auto'></iframe>"
    }
    let(:audio_embed_code_without_transcript_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
        }
        #fulcrum-embed-inner-fileset_id {
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          display:block;
          overflow:hidden;
          border-width:0;
          width:98%;
          max-width:98%;
          height:125px;
          margin:auto;
        }
      END
    }
    let(:audio_embed_code_with_transcript) {
      "<iframe src='#{presenter.embed_link}' title='#{presenter.embed_code_title}' style='page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; height:300px; margin:auto'></iframe>"
    }
    let(:audio_embed_code_with_transcript_css) {
      <<~END
        #fulcrum-embed-outer-fileset_id {
        }
        #fulcrum-embed-inner-fileset_id {
        }
        iframe#fulcrum-embed-iframe-fileset_id {
          page-break-inside:avoid;
          -webkit-column-break-inside:avoid;
          break-inside:avoid;
          display:block;
          overflow:hidden;
          border-width:0;
          width:98%;
          max-width:98%;
          height:300px;
          margin:auto;
        }
      END
    }
    let(:file_set_doc) { SolrDocument.new(id: 'fileset_id', has_model_ssim: ['FileSet'], mime_type_ssi: mime_type, resource_type_tesim: [resource_type], closed_captions_tesim: closed_captions) }
    let(:mime_type) { nil }
    let(:resource_type) { nil }
    let(:closed_captions) { nil }

    before do
      allow(presenter).to receive(:width).and_return(1920)
      allow(presenter).to receive(:height).and_return(1080)
      allow(dimensionless_presenter).to receive(:width).and_return('')
      allow(dimensionless_presenter).to receive(:height).and_return('')
    end

    context 'map FileSet' do
      let(:resource_type) { 'interactive map' }

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq map_embed_code
        expect(presenter.embed_code_css).to eq map_embed_code_css
      end
    end

    context 'image FileSet (landscape)' do
      let(:mime_type) { 'image/tiff' }

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq image_embed_code
        expect(presenter.embed_code_css).to eq image_embed_code_css
      end
    end

    context 'image FileSet (portrait)' do
      before do
        allow(presenter).to receive(:width).and_return(1080)
        allow(presenter).to receive(:height).and_return(1920)
      end

      let(:mime_type) { 'image/tiff' }

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq portrait_image_embed_code
        expect(presenter.embed_code_css).to eq portrait_image_embed_code_css
      end
    end

    context 'image FileSet (square)' do
      before do
        allow(presenter).to receive(:width).and_return(500)
        allow(presenter).to receive(:height).and_return(500)
      end

      let(:mime_type) { 'image/tiff' }

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq square_image_embed_code
        expect(presenter.embed_code_css).to eq square_image_embed_code_css
      end
    end

    context 'video FileSet' do
      let(:mime_type) { 'video/mp4' }

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq video_embed_code
        expect(presenter.embed_code_css).to eq video_embed_code_css
      end
    end

    context 'dimensionless map FileSet' do
      let(:resource_type) { 'interactive map' }

      it 'returns the expected embed codes and css' do
        expect(dimensionless_presenter.embed_code).to eq dimensionless_map_embed_code
        expect(dimensionless_presenter.embed_code_css).to eq dimensionless_map_embed_code_css
      end
    end

    context 'dimensionless image FileSet' do
      let(:mime_type) { 'image/tiff' }

      it 'returns the expected embed codes and css' do
        expect(dimensionless_presenter.embed_code).to eq dimensionless_image_embed_code
        expect(dimensionless_presenter.embed_code_css).to eq dimensionless_image_embed_code_css
      end
    end

    context 'dimensionless video FileSet' do
      let(:mime_type) { 'video/mp4' }

      it 'returns the expected embed codes and css' do
        expect(dimensionless_presenter.embed_code).to eq dimensionless_video_embed_code
        expect(dimensionless_presenter.embed_code_css).to eq dimensionless_video_embed_code_css
      end
    end

    context 'video with visual descriptions FileSet' do
      let(:mime_type) { 'video/mp4' }

      before do
        allow(presenter).to receive(:visual_descriptions).and_return('blah')
      end

      it 'returns the expected embed codes and css' do
        expect(presenter.embed_code).to eq video_with_visual_descriptions_embed_code
        expect(presenter.embed_code_css).to eq video_with_visual_descriptions_embed_code_css
      end
    end

    context 'audio FileSet' do
      let(:mime_type) { 'audio/mp3' }

      context 'no closed_captions present' do
        it 'returns the expected embed codes and css' do
          expect(presenter.embed_code).to eq audio_embed_code_without_transcript
          expect(presenter.embed_code_css).to eq audio_embed_code_without_transcript_css
        end
      end

      context 'closed_captions present' do
        let(:closed_captions) { ['STUFF'] }

        it 'returns the expected embed codes and css' do
          expect(presenter.embed_code).to eq audio_embed_code_with_transcript
          expect(presenter.embed_code_css).to eq audio_embed_code_with_transcript_css
        end
      end
    end

    context '#audio_without_closed_captions?' do
      context 'audio file' do
        let(:mime_type) { 'audio/mp3' }

        context 'no closed_captions present' do
          it { expect(presenter.audio_without_closed_captions?).to eq true }
        end

        context 'closed_captions present' do
          let(:closed_captions) { ['STUFF'] }

          it { expect(presenter.audio_without_closed_captions?).to eq false }
        end
      end

      context 'non-audio file' do
        let(:mime_type) { 'blerg' }

        context 'no closed_captions present' do
          it { expect(presenter.audio_without_closed_captions?).to eq false }
        end

        context 'closed_captions present' do
          let(:closed_captions) { ['STUFF'] }

          it { expect(presenter.audio_without_closed_captions?).to eq false }
        end
      end
    end
  end
end
